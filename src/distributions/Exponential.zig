const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;
const Io = std.Io;

const Distribution = @import("../Distribution.zig").Distribution;
const ziggurat = @import("../ziggurat.zig").ziggurat;
const exp_table = @import("../tables.zig").exp_table;

fn zigguratExponentialR(comptime Precision: type) Precision {
    if (Precision == f64) { return 7.697117470131050077; }
    else if (Precision == f32) { return 7.697117470; }
    else unreachable;
}

/// Implements the scale ($EE (X) = lambda$) exponential distribution.
/// $ f(x) = lambda*e^(-lambda x) $
/// The Method generator is the Inverse Algorithm, which is very slow
/// compared to the modern standard Ziggurat which is used by both
/// numpy and rust_dist.
/// Just give me time and I will implement it haha. this gives for free
/// the implementation of the standard normal distribution, which could be
/// cool to have
pub fn Exponential(comptime Precision: type) type {
    
    return struct {
        pub const Self = @This();
        pub const PDist = Distribution(Precision); 
        lambda: Precision,
        interface: PDist,

        /// Uses Ziggurat
        pub fn sample(self: *const Self, rng: Random) Precision {
            const u: Precision = ziggurat(rng, &exp_table, pdfStandard, zeroCase, false);
            return u / self.lambda;
        }
        /// Uses the inverse method RNG
        pub fn sampleInv(self: *const Self, rng: Random) Precision {
            const u = rng.float(Precision);
            return (1.0 / self.lambda) * (-@log(u));
        }

        pub fn sampleImpl(dist: *const Distribution(Precision), rng: Random) Precision {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(lambda: Precision) @This() {
            return .{
                .lambda = lambda,
                .interface = PDist{ .vtable = &.{ .sample = sampleImpl, .format = formatImpl } }
            };
        }

        pub fn zeroCase(rng: Random, e: Precision) Precision {
            _ = e;
            return rng.float(Precision) - zigguratExponentialR(Precision);
        }

        pub fn pdfStandard(x: Precision) Precision {
            return std.math.exp(-x);
        }

        /// To parse the JSON into the UnionDistr, it's needed to ignore the 
        /// .interface method when parsing the json to create the union!
        pub fn jsonParse(
            gpa: Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !Self {
            const Params = struct { lambda: Precision };

            const parsed = try std.json.innerParse(Params, gpa, source, options);

            return init(parsed.lambda);
        }

        fn formatImpl(dist: *const PDist, writer: *Io.Writer) !void {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            try self.format(writer);
        }

        pub fn format(self: *const Self, writer: *Io.Writer) !void {
            try writer.print("Exp{{λ={d:.2}}}", .{self.lambda});
        }

    };
}




