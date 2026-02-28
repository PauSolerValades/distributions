const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;

const Distribution = @import("Distribution.zig").Distribution;

pub fn Uniform(comptime Precision: type) type {
    
    return struct {
        const Self = @This(); // = Uniform(Precision)
        const PDist: type = Distribution(Precision);

        a: Precision,
        b: Precision,
        interface: PDist,

        /// Sample function to call without the interface
        pub inline fn sample(self: *Self, rng: Random) Precision {
            return self.a + (self.b - self.a) * rng.float(Precision);
        }

        /// Function to put into the VTable of Distribution
        fn sampleImpl(dist: *PDist, rng: Random) Precision {
            const self: *Self = @alignCast(@fieldParentPtr("interface", dist));
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

    };
}

