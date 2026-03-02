const std = @import("std");
const Io = std.Io;

const dist = @import("distributions");

const P = f64;
const Cont = dist.ContinousDistribution(P);

const Unif = dist.Uniform(P);
const Exp = dist.Exponential(P);
const Const = dist.Constant(P);


pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    
    var prng = std.Random.DefaultPrng.init(
        blk: {
            var os_seed: u64 = undefined;
            init.io.random(std.mem.asBytes(&os_seed));
            break :blk os_seed;
        }
    );
    const rng = prng.random();

    // another way to do polymorphism is wiht a union
    // in contrast with the interface approach, here Continous and Discrete distributions
    // cannot be in the same array.
    const dconst: [3]Cont = .{
        .{ .constant = Const.init(1) },
        .{ .exponential = Exp.init(2) },
        .{ .uniform = Unif.init(3, 4) },
    };

    for (dconst) |d| {
        try stdout_writer.print("Type {any} sampeled {d}\n", .{@TypeOf(d), d.sample(rng)});
    }
    try stdout_writer.flush();
}
