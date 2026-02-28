//! By convention, root.zig is the root source file when making a package.
const std = @import("std");

pub const Distribution = @import("Distribution.zig").Distribution;
pub const Exponential = @import("Exponential.zig").Exponential;
pub const Uniform = @import("Uniform.zig").Uniform;
