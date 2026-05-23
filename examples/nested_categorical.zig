const std = @import("std");
const Io = std.Io;

const distributions = @import("distributions");

const Continuous = distributions.ContinuousDistribution;

/// A config where each field is a Categorical that contains nested distributions.
/// When sampled, the categorical picks one distribution, then we sample it.
const Config = struct {
    // A categorical that picks between Exponential(λ=2) and Normal(μ=0, σ²=1)
    service_time: distributions.Categorical(f32, Continuous(f32)),
};

const content =
    \\{
    \\  "service_time": {
    \\    "categorical": {
    \\      "weights": [0.3, 0.7],
    \\      "data": [
    \\        { "exponential": { "lambda": 2.0 } },
    \\        { "normal": { "mean": 0.0, "variance": 1.0 } }
    \\      ]
    \\    }
    \\  }
    \\}
;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const options = std.json.ParseOptions{ .ignore_unknown_fields = true };
    const parsed = try std.json.parseFromSlice(Config, gpa, content, options);
    defer parsed.deinit();

    const seed = blk: {
        var os_seed: u64 = undefined;
        init.io.random(std.mem.asBytes(&os_seed));
        break :blk os_seed;
    };

    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();

    // Sample 10 times — two-step: categorical picks a distribution, then sample it
    try stdout_writer.writeAll("Nested categorical samples (10):\n");
    for (0..10) |_| {
        const dist = parsed.value.service_time.sample(rng);
        const value = dist.sample(rng);
        try stdout_writer.print("  {d:.4}\n", .{value});
    }

    try stdout_writer.flush();
}
