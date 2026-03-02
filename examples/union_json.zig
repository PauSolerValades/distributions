const std = @import("std");
const Io = std.Io;

const distributions = @import("distributions");

// as we want to use both discrete and continous distributions, we must import both unions
const Continuous = distributions.ContinuousDistribution;
const Discrete = distributions.DiscreteDistribution;

// this struct defines which type of distribution can the field hold
// any of those can be inited with it's precision
const Config = struct {
    inter_arrival_time: Continuous(f32),
    wait_time: Continuous(f64),
    boarding_time: Continuous(f64),
    user_action: Discrete(f32, u8),
};

// we define a json with the values implemented on the distributions
const content = 
    \\{
    \\  "inter_arrival_time": { "exponential": { "lambda": 2.0 } },  
    \\  "wait_time": { "constant": { "value": 5.0 } },
    \\  "boarding_time": { "uniform": { "a": 1, "b": 10 } },
    \\  "user_action": { "categorical": { "weights": [0.4, 0.6], "data": [0, 1] } }
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
    
    var config = parsed.value;

    const seed = blk: {
        var os_seed: u64 = undefined;
        init.io.random(std.mem.asBytes(&os_seed));
        break :blk os_seed;
    };

    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();
    
    try stdout_writer.print("Inter arrival time: {d}\n",.{config.inter_arrival_time.sample(rng)});
    try stdout_writer.print("Wait time: {d}\n",         .{config.wait_time.sample(rng)});
    try stdout_writer.print("Boarding time: {d}\n",     .{config.boarding_time.sample(rng)});
    try stdout_writer.print("User Action: {d}\n",       .{config.user_action.sample(rng)});

    try stdout_writer.flush();
}
