//! By convention, root.zig is the root source file when making a package.
const std = @import("std");

pub const Distribution = @import("Distribution.zig").Distribution;

pub const Constant = @import("distributions/Constant.zig").Constant;
pub const Exponential = @import("distributions/Exponential.zig").Exponential;
pub const Normal = @import("distributions/Normal.zig").Normal;
pub const Uniform = @import("distributions/Uniform.zig").Uniform;
pub const Interval = @import("distributions/Uniform.zig").Interval;

pub const Categorical = @import("distributions/Categorical.zig").Categorical;
pub const ECDF = @import("distributions/ECDF.zig").ECDF;

const unions = @import("UnionDist.zig");

pub const ContinuousDistribution = unions.ContinuousDistribution;
pub const DiscreteDistribution = unions.DiscreteDistribution;

test "Run all tests" {
    std.testing.refAllDecls(@This());
    try std.testing.expect(true);
}
