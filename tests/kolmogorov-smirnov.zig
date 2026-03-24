const std = @import("std");
const Allocator = std.mem.Allocator;

const dist = @import("distributions");
const Distribution = dist.Distribution;
const ECDF = dist.ECDF;
const Exp = dist.Exponential; 
const Norm = dist.Normal;

pub fn main(init: std.process.Init) !void {

    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), init.io, &.{});
    const stdout_writer = &stdout_file_writer.interface;

    var prng = std.Random.DefaultPrng.init(
        blk: {
            var os_seed: u64 = undefined;
            init.io.random(std.mem.asBytes(&os_seed));
            break :blk os_seed;
        }
    );
    const rng = prng.random();

    const alpha_99 = 1.95;
    const n_samples = 1024;
    const critical_value = alpha_99 / @sqrt(@as(f64, n_samples));

    try stdout_writer.print("Running KS Tests (n={d}, alpha=0.99, critical_val={d:.4})\n", .{ n_samples, critical_value });

    const exp: Exp(f64) = .init(1.0);
    const dexp = &exp.interface;

    var sample_exp: [n_samples]f64 = undefined;
    dexp.sampleBuffer(&sample_exp, rng);

    const Dn_exp = try ksTestCont(init.gpa, &sample_exp, &exp);
    const reject_exp = Dn_exp > critical_value;

    try stdout_writer.print("Exponential Exp(1):\n", .{});
    if (reject_exp) {
        try stdout_writer.print("  [FAIL] Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{Dn_exp});
    } else {
        try stdout_writer.print("  [PASS] Null not rejected. Sampler is accurate. D={d:.4}\n", .{Dn_exp});
    }

    const norm: Norm(f64) = .init(0.0, 1.0);
    const dnorm = &norm.interface; 

    var sample_norm: [n_samples]f64 = undefined;
    dnorm.sampleBuffer(&sample_norm, rng);

    const Dn_norm = try ksTestCont(init.gpa, &sample_norm, &norm);
    const reject_norm = Dn_norm > critical_value;

    try stdout_writer.print("\nNormal N(0, 1):\n", .{});
    if (reject_norm) {
        try stdout_writer.print("  [FAIL] Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{Dn_norm});
    } else {
        try stdout_writer.print("  [PASS] Null not rejected. Sampler is accurate. D={d:.4}\n", .{Dn_norm});
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
