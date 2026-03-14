const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;
const Io = std.Io;

const Distribution = @import("../Distribution.zig").Distribution;
const ziggurat = @import("../ziggurat.zig").ziggurat;
const table = @import("../tables.zig");


/// Implements the rate ($EE (X) = lambda$) exponential distribution.
/// $ f(x) = lambda*e^(-lambda x) $
/// It samples using the Ziggurat XOR method.
pub fn Exponential(comptime Precision: type) type {
    
    return struct {
        pub const Self = @This();
        pub const PDist = Distribution(Precision); 
        
        rate: Precision,
        interface: PDist,

        /// Uses Ziggurat
        pub fn sample(self: *const Self, rng: Random) Precision {
            const u: Precision = ziggurat(Precision, rng, &table.ExponentialTable(Precision), pdfStandard, zeroCase, false);
            return u / self.rate;
        }
        /// Uses the inverse method RNG
        pub fn sampleInv(self: *const Self, rng: Random) Precision {
            const u = rng.float(Precision);
            return (1.0 / self.rate) * (-@log(u));
        }

        pub fn sampleImpl(dist: *const Distribution(Precision), rng: Random) Precision {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(rate: Precision) @This() {
            return .{
                .rate = rate,
                .interface = PDist{ .vtable = &.{ .sample = sampleImpl, .format = formatImpl } }
            };
        }

        pub fn zeroCase(rng: Random, e: Precision) Precision {
            _ = e;
            return rng.float(Precision) - table.zigguratExponentialR(Precision);
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
            const Params = struct { rate: Precision };

            const parsed = try std.json.innerParse(Params, gpa, source, options);

            return init(parsed.lambda);
        }

        fn formatImpl(dist: *const PDist, writer: *Io.Writer) !void {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            try self.format(writer);
        }

        pub fn format(self: *const Self, writer: *Io.Writer) !void {
            try writer.print("Exp{{λ={d:.2}}}", .{self.rate});
        }

    };
}




