//! By convention, root.zig is the root source file when making a package.
const std = @import("std");

pub const Distribution = @import("Distribution.zig").Distribution;

pub const Constant = @import("Constant.zig").Constant;
pub const Uniform = @import("Uniform.zig").Uniform;
pub const Exponential = @import("Exponential.zig").Exponential;

pub const UnionDist = @import("UnionDist.zig").UnionDist;
