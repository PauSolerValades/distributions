pub const HypoExponential = @This();

const std = @import("std");
const assert = std.debug.assert;

const Distribution = @import("Distribution.zig").Distribution;

probs: []const f64,
rates: []const f64,
dimensions: u64,
interface: Distribution,

pub inline fn sample(self: *HyperExponential, rng: Random) f64 {
    const p = rng.float(f64);
    var cumulative: f64 = 0.0;

    for (self.probs, 0..) |prob, i| {
        cumulative += prob;
        if (p <= cumulative) {
            const u = rng.float(f64);
            return (1.0 / self.rates[i]) * (-@log(u));
        }
    }
    
    // Fallback
    const u = rng.float(f64);
    return (1.0 / self.rates[self.rates.len - 1]) * (-@log(u));
}

fn sampleImpl(dist: *Distribution, rng: Random) f64 {
    const self: *HyperExponential = @alignCast(@fieldParentPtr("interface", dist));
    return self.sample(rng);
}

pub fn init(probs: []const f64, rates: []const f64, dimensions: u64) HyperExponential {
    assert(probs.len == rates.len); // Safety check!
    return .{
        .probs = probs,
        .rates = rates,
        .dimensions = dimensions,
        .interface = .{ .vtable = &.{ .sample = sampleImpl } }
    };
}
