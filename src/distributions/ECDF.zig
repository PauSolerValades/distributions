const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;
const Io = std.Io;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Distribution = @import("../Distribution.zig").Distribution;


pub fn ECDF(comptime Precision: type, comptime DataType: type) type {

    return struct {
        const Self = @This();
        const PDist: type = Distribution(DataType);
        
        values: []DataType,
        prob: []Precision,
        cump: []Precision,
        interface: PDist,
        
        pub fn init(gpa: Allocator, data: []DataType) !Self {
            assert(data.len != 0); 

            switch(@typeInfo(DataType)) {
                .@"enum" => {
                    const Sorter = struct {
                        fn lessThan(_: void, a: DataType, b: DataType) bool {
                            return @intFromEnum(a) < @intFromEnum(b);
                        }
                    };
                    std.mem.sort(DataType, data, {}, comptime Sorter.lessThan);
                },
                .bool => {
                    const Sorter = struct {
                        fn lessThan(_: void, a: DataType, b: DataType) bool {
                            return @intFromBool(a) < @intFromBool(b);
                        }
                    };
                    std.mem.sort(DataType, data, {}, comptime Sorter.lessThan);
                },
                .int, .float => std.mem.sort(DataType, data, {}, comptime std.sort.asc(DataType)),
                else => @compileError("Type not supported for ECDF"), 
            }
            
            // find the duplicates
            var values: ArrayList(DataType) = .empty;
            var count: ArrayList(usize) = .empty;
            defer {
                values.deinit(gpa);
                count.deinit(gpa);
            }
    
            var c: usize = 1;
            for (1..data.len) |i| {
                if (data[i-1] == data[i]) { 
                    c += 1;
                } else {
                    try count.append(gpa, c);
                    try values.append(gpa, data[i-1]);
                    c = 1;
                }
            }
            
            try count.append(gpa, 1);
            try values.append(gpa, data[data.len-1]);

            const v = try values.toOwnedSlice(gpa);
            const cum = try gpa.alloc(Precision, v.len);
            const p = try gpa.alloc(Precision, v.len);

            const totalf: Precision = @floatFromInt(data.len);
            var cumulative_sum: usize = 0;

            for (count.items, 0..) |n, i| {
                cumulative_sum += n;
                const nf: Precision = @floatFromInt(cumulative_sum);
                cum[i] = nf / totalf;
                p[i] = @as(Precision, @floatFromInt(n)) / totalf;
            }

            return .{
                .values = v,
                .cump = cum,
                .prob = p,
                .interface = .{ .vtable = &.{ .sample = sampleImpl, .format = formatImpl } }
            };
        }

        pub fn deinit(self: *const Self, gpa: Allocator) void {
            gpa.free(self.cump);
            gpa.free(self.values);
            gpa.free(self.prob);
        }

    
        pub inline fn sample(self: *const Self, rng: Random) DataType {
            const u = rng.float(Precision);
            var i: usize = 0;
            for (self.cump) |a| {
                if (u <= a) break;
                i+=1;
            }
            return self.values[i];
        }

        /// Function to put into the VTable of Distribution
        fn sampleImpl(dist: *const PDist, rng: Random) DataType {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

                
        pub fn jsonParse(
            gpa: Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !Self {
            const Params = struct { data: []DataType };

            const parsed = try std.json.innerParse(Params, gpa, source, options);

            return init(gpa, parsed.data);
        }

        fn formatImpl(dist: *const PDist, writer: *Io.Writer) !void {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            try self.format(writer);
        }


        // Example: Categorical( (1, 0.1, 0.1), (2, 0.1, 0.2), (3, 0.1, 0.3) )
        pub fn format(self: *const Self, writer: *Io.Writer) !void {
            try writer.writeAll("ECDF{{ ");
            for (0..self.values.len - 1) |i| {
                try writer.print("({d:.2}, {d:.2}, {d:.2}) ", .{self.values[i], self.prob[i], self.cump[i]});
            }
            const last_i = self.values.len - 1;
            try writer.print("({d:.2}, {d:.2}, {d:.2}) }}\n", .{self.values[last_i], self.prob[last_i], self.cump[last_i]});
        }

    };
}

