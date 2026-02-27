pub const Erlang = @This();

const std = @import("std");
const assert = std.debug.assert;

const Distribution = @import("Distribution.zig").Distribution;

k: usize,
lambda: f64,
dimensions: u64,
interface: Distribution,

pub inline fn sample(self: *Erlang, rng: Random) f64 {
    var product_u: f64 = 1.0;
    for (0..self.k) |_| {
        product_u *= rng.float(f64);
    }
    // Protect against log(0)
    const safe_p = if (product_u == 0.0) std.math.floatEps(f64) else product_u;
    return -@log(safe_p) / self.lambda;
}

fn sampleImpl(dist: *Distribution, rng: Random) f64 {
    const self: *Erlang = @alignCast(@fieldParentPtr("interface", dist));
    return self.sample(rng);
}

pub fn init(k: usize, lambda: f64, dimensions: u64) Erlang {
    return .{
        .k = k,
        .lambda = lambda,
        .dimensions = dimensions,
        .interface = .{ .vtable = &.{ .sample = sampleImpl } }
    };
}
