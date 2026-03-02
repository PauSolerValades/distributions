const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;

const Distribution = @import("../Distribution.zig").Distribution;

/// Implementation of the Uniform Distribution:
/// $ f(x) = frac(1, b-a) $
/// $ F(x) = 
pub fn Uniform(comptime Precision: type) type {
    
    return struct {
        const Self = @This(); // = Uniform(Precision)
        const PDist: type = Distribution(Precision);

        a: Precision,
        b: Precision,
        interface: PDist,
    
        // uses the rng instance to get a float between 0 and 1 and then scales it
        pub inline fn sample(self: *const Self, rng: Random) Precision {
            return self.a + (self.b - self.a) * rng.float(Precision);
        }

        /// Function to put into the VTable of Distribution
        fn sampleImpl(dist: *const PDist, rng: Random) Precision {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(a: Precision, b: Precision) Self {
            assert(b > a);
            return .{
                .a = a,
                .b = b,
                .interface = .{ .vtable = &.{ .sample = sampleImpl } }
            };
        }
        
        pub fn jsonParse(
            allocator: std.mem.Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !Self {
            const Params = struct { a: Precision, b: Precision };

            const parsed = try std.json.innerParse(Params, allocator, source, options);

            return init(parsed.a, parsed.b);
        }

    };
}

