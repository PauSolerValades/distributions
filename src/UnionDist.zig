const std = @import("std");
const Random = std.Random;
const Exponential = @import("Exponential.zig").Exponential;
const Uniform = @import("Uniform.zig").Uniform;
const Constant = @import("Constant.zig").Constant;

pub fn UnionDist(comptime Precision: type) type {
    
    return union(enum) {
        const Self = @This();

        constant: Constant(Precision),
        exponential: Exponential(Precision),
        uniform: Uniform(Precision),

        pub fn sample(self: *Self, rng: Random) Precision {
            switch(self.*) {
                // generates this:
                // .constant => |*c| return c.sample(rng),
                // .exponential => |*exp| return exp.sample(rng),
                // .uniform => |*unif| return unif.sample(rng),
                // ...
                inline else => |*dist| return dist.sample(rng),
            }
        }
    };
}

