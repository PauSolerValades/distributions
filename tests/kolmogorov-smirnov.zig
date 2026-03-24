const std = @import("std");
const Allocator = std.mem.Allocator;

const dist = @import("distributions");
const Distribution = dist.Distribution;
const ECDF = dist.ECDF;
const Exp = dist.Exponential; 

pub fn main(init: std.process.Init) !void {
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

    const Dn = try ksTestCont(init.gpa, &sample, &exp);
    
    const alpha_99 = 1.95;
    const reject_null = @sqrt(1024.0) * Dn > alpha_99;
    if (reject_null) {
        std.debug.print("Null is rejected (IE your sample does not follow the distribution). p={d}\n", .{Dn});
    } else {
        std.debug.print("Null is not rejected (your samples indeed follows the distribution) p={d}\n", .{Dn});
    }
}

/// Compute p-value with an \alpha=0.99 with a Kolmogorov-Smirnov test for continuous distributions
pub fn ksTestCont(gpa: std.mem.Allocator, sample: []f64, d: anytype) !f64 {
    const ecdf = try ECDF(f64, f64).init(gpa, sample);
    defer ecdf.deinit(gpa);

    const values = ecdf.bins.items(.value);
    const cump = ecdf.bins.items(.cump);
    const num_distinct_samples = ecdf.bins.len;
    
    var max_diff: f64 = 0;
    var p_prev: f64 = 0.0;

    for (0..num_distinct_samples) |i| {
        const fei = values[i]; 
        const p = cump[i];
        
        const pi = d.cdf(fei);

        const diff_top = @abs(p - pi);
        const diff_bottom = @abs(p_prev - pi);

        max_diff = @max(max_diff, @max(diff_top, diff_bottom));
        p_prev = p;
    }
    
    return max_diff;
}
