const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;
const Allocator = std.mem.Allocator;

const Distribution = @import("../Distribution.zig").Distribution;

/// Implementation of the Categorical Distribution:
/// $ P(X = i) = p_i
pub fn Categorical(comptime Precision: type, comptime DataType: type) type {
    
    const weightsInfo = @typeInfo(Precision);
    
    if (weightsInfo != .float) @compileError("Weights must be a floating point type");
    
    return struct {
        const Self = @This(); // = Uniform(Precision)
        const PDist: type = Distribution(DataType);
        
        weights: []const Precision,
        data: []const DataType,
        acc: []const Precision,
        interface: PDist,
        
    
        // uses the rng instance to get a float between 0 and 1 and then scales it
        pub inline fn sample(self: *const Self, rng: Random) DataType {
            const u = rng.float(Precision);
            var i: usize = 0;
            for (self.acc) |a| {
                if (u <= a) break;
                i+=1;
            }
            return self.data[i];
        }

        /// Function to put into the VTable of Distribution
        fn sampleImpl(dist: *const PDist, rng: Random) DataType {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(gpa: Allocator, weights: []const Precision, data: []const DataType) !Self {
            assert(weights.len == data.len);

            var acc = try gpa.alloc(Precision, weights.len);
            var sum: Precision = 0.0;
            for (weights, 0..) |weight, i| {
                sum += weight;
                acc[i] = sum;
            }
            
            assert(sum == 1.0);

            return .{
                .weights = weights,
                .acc = acc,
                .data = data,
                .interface = .{ .vtable = &.{ .sample = sampleImpl } }
            };
        }

        pub fn deinit(self: *const Self, gpa: Allocator) void {
            gpa.free(self.acc);
        }
        
        pub fn jsonParse(
            allocator: std.mem.Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !Self {
            const Params = struct { weights: Precision, data: DataType };

            const parsed = try std.json.innerParse(Params, allocator, source, options);

            return init(parsed.a, parsed.b);
        }
    };
}

