pub const HypoExponential = @This();

const std = @import("std");
const assert = std.debug.assert;

const Distribution = @import("Distribution.zig").Distribution;

rates: []const f64,
dimensions: u64,
interface: Distribution,

pub inline fn sample(self: *HypoExponential, rng: Random) f64 {
    var sum: f64 = 0.0;
    for (self.rates) |lambda| {
        const u = rng.float(f64);
        sum += (1.0 / lambda) * (-@log(u));
    }
    return sum;
}

fn sampleImpl(dist: *Distribution, rng: Random) f64 {
    const self: *HypoExponential = @alignCast(@fieldParentPtr("interface", dist));
    return self.sample(rng);
}

pub fn init(rates: []const f64, dimensions: u64) HypoExponential {
    return .{
        .rates = rates,
        .dimensions = dimensions,
        .interface = .{ .vtable = &.{ .sample = sampleImpl } }
    };
}


