const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Distribution = @import("../Distribution.zig").Distribution;


pub fn ECDF(comptime Precision: type, comptime DataType: type) type {

    return struct {
        const Self = @This();
        const PDist: type = Distribution(DataType);
        
        values: []DataType,
        cump: []Precision,
        interface: PDist,
        
    
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

        pub fn init(gpa: Allocator, data: []DataType) !Self {
            assert(data.len != 0); 
            // Sort the list
            std.mem.sort(DataType, data, {}, comptime std.sort.asc(DataType));
            
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
            const p = try gpa.alloc(Precision, v.len);

            const totalf: Precision = @floatFromInt(data.len);
            var cumulative_sum: usize = 0;

            for (count.items, 0..) |n, i| {
                cumulative_sum += n;
                const nf: Precision = @floatFromInt(cumulative_sum);
                p[i] = nf / totalf;
            }

            return .{
                .values = v,
                .cump = p,
                .interface = .{ .vtable = &.{ .sample = sampleImpl } }
            };
        }

        pub fn deinit(self: *const Self, gpa: Allocator) void {
            gpa.free(self.cump);
            gpa.free(self.values);
        }
        
        pub fn jsonParse(
            allocator: std.mem.Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !Self {
            const Params = struct { data: DataType };

            const parsed = try std.json.innerParse(Params, allocator, source, options);

            return init(parsed.a, parsed.b);
        }
    };
}

