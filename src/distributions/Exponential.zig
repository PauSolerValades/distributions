const std = @import("std");
const Random = std.Random;

const Distribution = @import("../Distribution.zig").Distribution;

/// Implements the scale ($EE (X) = lambda$) exponential distribution.
/// $ f(x) = lambda*e^(-lambda x) $
pub fn Exponential(comptime Precision: type) type {
    
    return struct {
        pub const Self = @This();
        pub const PDist = Distribution(Precision); 
        lambda: Precision,
        interface: PDist,

        /// Uses the inverse method RNG
        pub fn sample(self: *const Self, rng: Random) Precision {
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
                .interface = PDist{ .vtable = &.{ .sample = sampleImpl } }
            };
        }

        /// To parse the JSON into the UnionDistr, it's needed to ignore the 
        /// .interface method when parsing the json to create the union!
        pub fn jsonParse(
            allocator: std.mem.Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !Self {
            const Params = struct { lambda: Precision };

            const parsed = try std.json.innerParse(Params, allocator, source, options);

            return init(parsed.lambda);
        }

    };
}

