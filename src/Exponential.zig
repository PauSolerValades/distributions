const std = @import("std");
const Random = std.Random;

const Distribution = @import("Distribution.zig").Distribution;

/// Implements the scale ($EE (X) = lambda$) exponential distribution.
/// $ f(x) = lambda*e^(-lambda x) $
pub fn Exponential(comptime Precision: type) type {
    
    return struct {
        pub const Self = @This();
        lambda: Precision,
        interface: Distribution(Precision),

        /// Uses the inverse method RNG
        pub fn sample(self: *Self, rng: Random) Precision {
            const u = rng.float(Precision);
            return (1.0 / self.lambda) * (-@log(u));
        }

        pub fn sampleImpl(dist: *Distribution(Precision), rng: Random) Precision {
            const self: *Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(lambda: Precision) @This() {
            return .{
                .lambda = lambda,
                .interface = Distribution(Precision){
                    .vtable = &.{ .sample = sampleImpl }
                }
            };
        }

    };
}

