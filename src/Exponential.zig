pub const Exponential = @This();

const std = @import("std");
const Random = std.Random;
const Dist = @import("Distribution.zig");
const Distribution = Dist.Distribution;

lambda: f64,
dimensions: u64,
interface: Distribution,

pub fn sample(dist: *Distribution, rng: Random) f64 {
    const self: *Exponential = @alignCast(@fieldParentPtr("interface", dist));
    const u = rng.float(f64);
    return (1.0 / self.lambda) * (-@log(u));
}

pub fn init(lambda: f64, dimensions: u64) Exponential {
    return .{
        .lambda = lambda,
        .dimensions = dimensions,
        .interface = Distribution{
            .vtable = &.{ .sample = sample }
        }
    };
}
