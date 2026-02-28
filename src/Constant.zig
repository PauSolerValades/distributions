const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;

const Distribution = @import("Distribution.zig").Distribution;

/// Implementation of a constant:
/// $ f(x) = c $
/// $ F(x) = cx $
pub fn Constant(comptime Precision: type) type {
    
    return struct {
        const Self = @This(); // = Uniform(Precision)
        const PDist: type = Distribution(Precision);

        c: Precision,
        interface: PDist,
       
        // uses the rng instance to get a float between 0 and 1 and then scales it
        pub inline fn sample(self: *Self, rng: Random) Precision {
            _ = rng;
            return self.c;
        }

        /// Function to put into the VTable of Distribution
        fn sampleImpl(dist: *PDist, rng: Random) Precision {
            const self: *Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(c: Precision) Self {
            return .{
                .c = c,
                .interface = .{ .vtable = &.{ .sample = sampleImpl } }
            };
        }

    };
}

