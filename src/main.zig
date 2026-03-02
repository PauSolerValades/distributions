const std = @import("std");
const Io = std.Io;

const stats = @import("stats");

const Unif = stats.Uniform(f32);
const Exp = stats.Exponential(f32);
const Dist = stats.Distribution(f32);
const Const = stats.Constant(f32);
const Cat = stats.Categorical(f32, i32);

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

    const exp: Exp = .init(2); 
    const dexp: *const Dist = &exp.interface; //ptr distribution
    const e = dexp.sample(rng);
   
    var esample: [40]f32 = undefined;
    dexp.sampleBuffer(&esample, rng);

    try stdout_writer.print("Exponential sample: {d}\n", .{e});
    try stdout_writer.print("Exponential Buffer {any}\n", .{esample});
   
    const unif: Unif = .init(10, 20); 
    const dunf: *const Dist = &unif.interface; //ptr distribution
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
    
    const weights = [_]f32{0.1, 0.15, 0.25, 0.5};
    const data = [_]i32{-2, -2, 0, 3};
    const cat: Cat = try .init(init.gpa, &weights, &data);
    defer cat.deinit(init.gpa);
    const dcat: *const stats.Distribution(i32) = &cat.interface;
    const c = dcat.sample(rng);

    try stdout_writer.print("Categorical sample: {d}\n", .{c});
    // const d = stats.UnionDist(f32){ .exponential = Exp.init(4) };
   
    var da = [_]i32{-2, -2, 0, 3};
    const ecdf: stats.ECDF(f32, i32) = try .init(init.gpa, &da);
    defer ecdf.deinit(init.gpa);
    const decdf: *const stats.Distribution(i32) = &ecdf.interface;
    const a: i32 = decdf.sample(rng);

    try stdout_writer.print("ECDF sample: {d}\n", .{a});
    
    var d = stats.UnionDist(f32){ .constant = Const.init(1) };
    
    try stdout_writer.print("Union: {any}\n", .{d});
    
    for (0..100) |_| {
        try stdout_writer.print("{d} ", .{d.sample(rng)});
    }
    try stdout_writer.flush();
}


