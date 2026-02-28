const std = @import("std");
const Io = std.Io;

const stats = @import("stats");

pub fn main(init: std.process.Init) !void {
    //const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    
    const seed = blk: {
        var os_seed: u64 = undefined;
        init.io.random(std.mem.asBytes(&os_seed));
        break :blk os_seed;
    };

    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();

    var exp: stats.Exponential(f32) = .init(2); 
    const dexp: *stats.Distribution(f32) = &exp.interface; //ptr distribution
    const ed = dexp.sample(rng);
   
    var sample: [40]f64 = undefined;
    dexp.sampleBuffer(&sample, rng);

    try stdout_writer.print("{d}\n", .{ed});
    try stdout_writer.print("{any}\n", .{sample});

    try stdout_writer.flush(); // Don't forget to flush!
    
}


