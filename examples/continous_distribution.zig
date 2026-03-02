const std = @import("std");
const Io = std.Io;

const dist = @import("distributions");
const P: type = f32;

// we define aliases for a given precision P to use 
const Unif = dist.Uniform(P);
const Exp = dist.Exponential(P);
const Dist = dist.Distribution(P);
const Const = dist.Constant(P);

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    
    var prng = std.Random.DefaultPrng.init(
        blk: {
            var os_seed: u64 = undefined;
            init.io.random(std.mem.asBytes(&os_seed));
            break :blk os_seed;
        }
    );
    const rng = prng.random();
    
    // lets create an Exponential distribution
    const exp: Exp = .init(2); 
    const dexp: *const Dist = &exp.interface; // this object is const
    try stdout_writer.print("Exponential sample: {d}\n", .{dexp.sample(rng)});
    
    // fill a buffer with samples
    var esample: [40]f32 = undefined;
    try stdout_writer.print("Exponential Buffer {any}\n", .{dexp.sampleBuffer(&esample, rng)});
  
    // create a uniform distribution
    const unif: Unif = .init(10, 20); 
    const dunf: *const Dist = &unif.interface;
    try stdout_writer.print("Uniform sample: {d}\n", .{dunf.sample(rng)});
   
    var usample: [40]f32 = undefined;
    try stdout_writer.print("Uniform Buffer {any}\n", .{dunf.sampleBuffer(&usample, rng)});
  
    // the use of the intrusive interface pattern can allow us mix different distributions into
    // one single array without any overhead
    const enemies: [4]*const Dist = .{
        &Unif.init(5,10).interface, 
        &Unif.init(20, 30).interface, 
        &Exp.init(4).interface, 
        &Exp.init(10).interface
    };

    for (enemies, 0..) |enemy, i| {
        try stdout_writer.print("Enemy {d} attacks with {d} damage (from a {any})\n", .{i, enemy.sample(rng), @TypeOf(enemy)});
    }

    // if the interface is not your thing, you can directly sample from the distribution without
    // using the interface.
    const ex = exp.sample(rng);
    const un = unif.sample(rng);

    try stdout_writer.print("No interface exp and unif: {d} {d}\n", .{ex, un});

    try stdout_writer.flush();
}


