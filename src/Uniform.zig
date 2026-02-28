pub const Uniform = @This();

const std = @import("std");
const assert = std.debug.assert;
const Random = std.Random;

const Distribution = @import("Distribution.zig").Distribution;

a: f64,
b: f64,
interface: Distribution,

/// Sample function to call without the interface
pub inline fn sample(self: *Uniform, rng: Random) f64 {
    return self.a + (self.b - self.a) * rng.float(f64);
}

/// Function to put into the VTable of Distribution
fn sampleImpl(dist: *Distribution, rng: Random) f64 {
    const self: *Uniform = @alignCast(@fieldParentPtr("interface", dist));
    return self.sample(rng);
}

pub fn init(a: f64, b: f64) Uniform {
    assert(b > a);
    return .{
        .a = a,
        .b = b,
        .interface = .{ .vtable = &.{ .sample = sampleImpl } }
    };
}
