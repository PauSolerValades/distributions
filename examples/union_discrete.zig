const std = @import("std");
const Io = std.Io;

const dist = @import("distributions");

const P = f64;
const DiscDist = dist.DiscreteDistribution;

const ECDF = dist.ECDF; 
const Cat = dist.Categorical;

pub const Action = enum { nothing, like, repost };

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

    // to make an ECDF with an enum we need a list of the enum 
    // the data must be var as it will be sorted in place
    var ecdf_enum_data = [_]Action{ .like, .nothing, .repost, .like, .like };
    const ecdf_enum: ECDF(P, Action) = try .init(init.gpa, &ecdf_enum_data);
    defer ecdf_enum.deinit(init.gpa);

    var ecdf_float_data = [_]P{ 1.5, 0.2, 1.5, 3.8, 2.1, 5.5 };
    const ecdf_float: ECDF(P, f64) = try .init(init.gpa, &ecdf_float_data);
    defer ecdf_float.deinit(init.gpa);

    const cat_enum_weights = [_]P{ 0.1, 0.7, 0.2 };
    const cat_enum_data = [_]Action{ .nothing, .like, .repost };
    const cat_enum: Cat(P, Action) = try .init(init.gpa, &cat_enum_weights, &cat_enum_data);
    defer cat_enum.deinit(init.gpa);

    const cat_int_weights = [_]P{ 0.5, 0.5 };
    const cat_int_data = [_]u32{ 100, 200 };
    const cat_int: Cat(P, u32) = try .init(init.gpa, &cat_int_weights, &cat_int_data);
    defer cat_int.deinit(init.gpa);

    
    try stdout_writer.print("ECDF ({f}) sampled: {any}\n", .{ecdf_enum, ecdf_enum.sample(rng)});
    try stdout_writer.print("ECDF ({f})  sampled: {d:.2}\n\n", .{ecdf_enum, ecdf_float.sample(rng)});

    try stdout_writer.print("Cat ({f})  sampled: {any}\n", .{cat_enum, cat_enum.sample(rng)});
    try stdout_writer.print("Cat ({f})   sampled: {d}\n", .{cat_int, cat_int.sample(rng)});

    try stdout_writer.flush();
}
