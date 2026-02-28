const std = @import("std");
const Io = std.Io;

const stats = @import("stats");

const Unif = stats.Uniform(f32);
const Exp = stats.Exponential(f32);
const Dist = stats.Distribution(f32);

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

    var exp: Exp = .init(2); 
    const dexp: *Dist = &exp.interface; //ptr distribution
    const e = dexp.sample(rng);
   
    var esample: [40]f32 = undefined;
    dexp.sampleBuffer(&esample, rng);

    try stdout_writer.print("Exponential sample: {d}\n", .{e});
    try stdout_writer.print("Exponential Buffer {any}\n", .{esample});
   
    var unif: Unif = .init(10, 20); 
    const dunf: *Dist = &unif.interface; //ptr distribution
    const u = dunf.sample(rng);
   
    var usample: [40]f32 = undefined;
    dunf.sampleBuffer(&usample, rng);

    try stdout_writer.print("Uniform sample: {d}\n", .{u});
    try stdout_writer.print("Uniform Buffer {any}\n", .{usample});
    
    // use it without the inerface, if you want!
    const ex = exp.sample(rng);
    const un = unif.sample(rng);

    try stdout_writer.print("No interface: {d} {d}\n", .{ex, un});

    try stdout_writer.flush(); // Don't forget to flush!
}


