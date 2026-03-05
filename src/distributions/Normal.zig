const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;
const Io = std.Io;

const Distribution = @import("../Distribution.zig").Distribution;
const ziggurat = @import("../ziggurat.zig").ziggurat;
const table = @import("../tables.zig");
const uniform = @import("Uniform.zig");
const Uniform = uniform.Uniform;
const Interval = uniform.Interval;

/// Implements the scale ($EE (X) = lambda$) exponential distribution.
/// $ f(x) = lambda*e^(-lambda x) $
/// The Method generator is the Inverse Algorithm, which is very slow
/// compared to the modern standard Ziggurat which is used by both
/// numpy and rust_dist.
/// Just give me time and I will implement it haha. this gives for free
/// the implementation of the standard normal distribution, which could be
/// cool to have
pub fn Normal(comptime Precision: type) type {
    
    return struct {
        pub const Self = @This();
        pub const PDist = Distribution(Precision); 

        mu: Precision,
        sigma: Precision, // represents sigma^2, but i don't want to write it down
        interface: PDist,

        /// Uses Ziggurat
        pub fn sample(self: *const Self, rng: Random) Precision {
            const u: Precision = ziggurat(
                Precision, 
                rng, 
                &table.NormalTable(Precision), 
                pdfStandard, 
                zeroCase, 
                true 
            );
            return (u * self.sigma) + self.mu;
        }
        

        pub fn sampleImpl(dist: *const Distribution(Precision), rng: Random) Precision {
            const self: *const Self = @alignCast(@fieldParentPtr("interface", dist));
            return self.sample(rng);
        }

        pub fn init(mu: Precision, sigma: Precision) @This() {
            return .{
                .mu = mu,
                .sigma = sigma,
                .interface = PDist{ .vtable = &.{ .sample = sampleImpl, .format = formatImpl } }
            };
        }

        pub fn zeroCase(rng: Random, u: Precision) Precision {
            var x: Precision = 1.0;
            var y: Precision = 0.0;
            
            const unif: Uniform(Precision) = .init(0,1, Interval.oo);
            while (-2.0 * y < x*x) {
                const x_ = unif.sample(rng);
                const y_ = unif.sample(rng);

                x = @log(x_) / table.zigguratNormalR(Precision);
                y = @log(y_); 
            }

            if (u < 0.0) {
                return x - table.zigguratNormalR(Precision);
            } else {
                return table.zigguratNormalR(Precision) - x;
            }
        }

        pub fn pdfStandard(x: Precision) Precision {
            const pi = std.math.pi;
            const exp = std.math.exp;
            return (1.0 / @sqrt(2 * pi)) * exp(- (x*x) / 2.0);
        }

        pub fn pdf(self: *const Self, x: Precision) Precision {
            const pi = std.math.pi;
            const exp = std.math.exp;
            return (1 / @sqrt(2 * pi)*self.sigma) * exp(- (x-self.mu)*(x-self.mu) / 2*self.sigma);
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
            try writer.print("Exp{{mu={d:.2}, sigma^2={d:.2}}}", .{self.mu, self.sigma});
        }

    };
}




