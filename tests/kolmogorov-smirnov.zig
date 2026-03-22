const std = @import("std");
const Allocator = std.mem.Allocator;

const dist = @import("distributions");
const ECDF = dist.ECDF;
const Exp = dist.Exponential; 

pub fn main(init: std.process.Init) void {
    var prng = std.Random.DefaultPrng.init(
        blk: {
            var os_seed: u64 = undefined;
            init.io.random(std.mem.asBytes(&os_seed));
            break :blk os_seed;
        }
    );
    const rng = prng.random();

    const exp: Exp(f64) = .init(1);
    const dexp = &exp.interface;

    var sample: [1024]f64 = undefined;
    dexp.sampleBuffer(&sample, rng);

    ksTest(init.gpa, &sample, exp.cdf);
}

/// Compute p-value with an $alpha=0.99$ with a Kolmogorov-Smirnov test
pub fn ksTest(gpa: Allocator, sample: []f64, cdf: *const fn(f64) f64) f64 {
    _ = cdf;

    const ecdf: ECDF(f64, f64) = try .init(sample);
   
    // const values = ecdf.bins.items(.value);
    const cump = ecdf.bins.items(.cum);
    const num_distinct_samples = ecdf.bins.len;

    // 1. Compute the number of each sample elements in the ECDF.
    const num_observations = try gpa.alloc(u64, num_distinct_samples);
    
    for (0..num_distinct_samples-1) |i| {
        const p_i = cump[i+1] - cump[i];
        const float_obs_i = @as(f64, @floatFromInt(num_distinct_samples)) / p_i; // this should be an int!
        num_observations[i] = @intFromFloat(float_obs_i);

    }

    std.debug.print("{any}\n", .{num_distinct_samples});
}

