const std = @import("std");
const Io = std.Io;

const dist = @import("distributions");

// distrete distributions differentiate between the precision and the datatype
// - precision: type of the rng and probabilities needed to sample from the dist.
// - datatype: type of the actual data stored
//
// we define an aliase with the precision (f32) and 
const Action = enum { atack, move, defend, flee };
const Cat = dist.Categorical(f32, Action);
const ECDF = dist.ECDF(f32, i32);

const Distribution = dist.Distribution;

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

    // Categorical distribution: chose from an array with diferent weights per element.
    // let's make the examples as Actions to be perfomed by a user 
    const data = [_]Action{.atack, .move, .defend, .flee};
    const weights = [_]f32{0.1, 0.15, 0.25, 0.5}; // probailites to every atach
    
    // create the distribution. All distributions that use arrays they need an allocator.
    const cat: Cat = try .init(init.gpa, &weights, &data);
    defer cat.deinit(init.gpa); 
    const dcat: *const Distribution(Action) = &cat.interface; // intrusive interface pattern

    // let's decide which actions does the png in the next 4 turns
    for (0..5) |i| {
        try stdout_writer.print("Png does {d} at turn {d}.\n", .{dcat.sample(rng), i});
    }
  
    // the other data dependant distribution is the ECDF from a given set of data.
    // this 
    var obs = [_]i32{-4, -5, 2, 0, 8, 3, -4, 2, 3, 3};

    const ecdf: ECDF = try .init(init.gpa, &obs);
    defer ecdf.deinit(init.gpa); // needs heap memory
                                
    // when creating the object, the data is sorted, counted and given weigths.
    // this can be accessed like this:
    try stdout_writer.print("Accumulated probability: {any}\n Distinct values: {any}\n", .{ecdf.cump, ecdf.values});

    const decdf = &ecdf.interface;
    const a: i32 = decdf.sample(rng);

    try stdout_writer.print("ECDF sample: {d}\n", .{a});
    
    try stdout_writer.flush();
}

    
