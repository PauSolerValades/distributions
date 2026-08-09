const std = @import("std");
const Allocator = std.mem.Allocator;

const dist = @import("distributions");
const Distribution = dist.Distribution;
const ECDF = dist.ECDF;
const Exp = dist.Exponential;
const Pareto = dist.Pareto;
const Norm = dist.Normal;
const Unif = dist.Uniform;
const Interval = dist.Interval;
const Lognormal = dist.Lognormal;
const Weibull = dist.Weibull;

pub fn main(init: std.process.Init) !void {
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), init.io, &.{});
    const stdout_writer = &stdout_file_writer.interface;

    var prng = std.Random.DefaultPrng.init(blk: {
        var os_seed: u64 = undefined;
        init.io.random(std.mem.asBytes(&os_seed));
        break :blk os_seed;
    });
    const rng = prng.random();

    const alpha_99 = 1.95;
    const n_samples = 1024;
    const critical_value = alpha_99 / @sqrt(@as(f64, n_samples));

    try stdout_writer.print("Running KS Tests (n={d}, alpha=0.99, critical_val={d:.4})\n", .{ n_samples, critical_value });

    const exp: Exp(f64) = .init(1.0);
    const dexp = &exp.interface;

    var sample_exp: [n_samples]f64 = undefined;
    dexp.sampleBuffer(&sample_exp, rng);

    const Dn_exp = try ksTest(init.gpa, &sample_exp, &exp);
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

    const Dn_norm = try ksTest(init.gpa, &sample_norm, &norm);
    const reject_norm = Dn_norm > critical_value;

    try stdout_writer.print("\nNormal N(0, 1):\n", .{});
    if (reject_norm) {
        try stdout_writer.print("  [FAIL] Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{Dn_norm});
    } else {
        try stdout_writer.print("  [PASS] Null not rejected. Sampler is accurate. D={d:.4}\n", .{Dn_norm});
    }

    try stdout_writer.print("\nUniform U(2, 5) (all intervals):\n", .{});
    inline for (.{ Interval.co, Interval.oc, Interval.oo, Interval.cc }) |intvl| {
        const unif: Unif(f64) = .init(2.0, 5.0, intvl);
        const dunif = &unif.interface;

        var sample_unif: [n_samples]f64 = undefined;
        dunif.sampleBuffer(&sample_unif, rng);

        const Dn_unif = try ksTest(init.gpa, &sample_unif, &unif);
        const reject_unif = Dn_unif > critical_value;

        if (reject_unif) {
            try stdout_writer.print("  [FAIL] {s}: Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{ @tagName(intvl), Dn_unif });
        } else {
            try stdout_writer.print("  [PASS] {s}: Null not rejected. Sampler is accurate. D={d:.4}\n", .{ @tagName(intvl), Dn_unif });
        }
    }

    const pareto: Pareto(f64) = Pareto(f64).init(2.5, 1.0);
    const dpareto = &pareto.interface;

    var sample_pareto: [n_samples]f64 = undefined;
    dpareto.sampleBuffer(&sample_pareto, rng);

    const Dn_pareto = try ksTest(init.gpa, &sample_pareto, &pareto);
    const reject_pareto = Dn_pareto > critical_value;

    try stdout_writer.print("\nPareto(α=2.50, x_m=1.00):\n", .{});
    if (reject_pareto) {
        try stdout_writer.print("  [FAIL] Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{Dn_pareto});
    } else {
        try stdout_writer.print("  [PASS] Null not rejected. Sampler is accurate. D={d:.4}\n", .{Dn_pareto});
    }

    const lognorm: Lognormal(f64) = Lognormal(f64).init(0, 1);
    const dlognorm = &lognorm.interface;

    var sample_lognorm: [n_samples]f64 = undefined;
    dlognorm.sampleBuffer(&sample_lognorm, rng);

    const Dn_lognorm = try ksTest(init.gpa, &sample_lognorm, &lognorm);
    const reject_lognorm = Dn_lognorm > critical_value;

    try stdout_writer.print("\nLognormal(0, 1):\n", .{});
    if (reject_lognorm) {
        try stdout_writer.print("  [FAIL] Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{Dn_lognorm});
    } else {
        try stdout_writer.print("  [PASS] Null not rejected. Sampler is accurate. D={d:.4}\n", .{Dn_lognorm});
    }

    const weibull: Weibull(f64) = Weibull(f64).init(1.0, 2.0);
    const dweibull = &weibull.interface;

    var sample_weibull: [n_samples]f64 = undefined;
    dweibull.sampleBuffer(&sample_weibull, rng);

    const Dn_weibull = try ksTest(init.gpa, &sample_weibull, &weibull);
    const reject_weibull = Dn_weibull > critical_value;

    try stdout_writer.print("\nWeibull(λ=1.00, k=2.00):\n", .{});
    if (reject_weibull) {
        try stdout_writer.print("  [FAIL] Null rejected. Sample does NOT follow distribution. D={d:.4}\n", .{Dn_weibull});
    } else {
        try stdout_writer.print("  [PASS] Null not rejected. Sampler is accurate. D={d:.4}\n", .{Dn_weibull});
    }
}

/// Kolmogorov-Smirnov test statistic against the distribution's cdf. Works for int and float samples.
pub fn ksTest(gpa: std.mem.Allocator, sample: anytype, d: anytype) !f64 {
    const T = std.meta.Elem(@TypeOf(sample));
    const ecdf = try ECDF(f64, T).init(gpa, sample);
    defer ecdf.deinit(gpa);

    const values = ecdf.bins.items(.value);
    const cump = ecdf.bins.items(.cump);
    const num_distinct_samples = ecdf.bins.len;

    var max_diff: f64 = 0;
    var p_prev: f64 = 0.0;

    for (0..num_distinct_samples) |i| {
        const fei: f64 = switch (@typeInfo(T)) {
            .int => @floatFromInt(values[i]),
            .float => @floatCast(values[i]),
            else => unreachable,
        };
        const p = cump[i];

        const pi = d.cdf(fei);

        const diff_top = @abs(p - pi);
        const diff_bottom = @abs(p_prev - pi);

        max_diff = @max(max_diff, @max(diff_top, diff_bottom));
        p_prev = p;
    }

    return max_diff;
}
