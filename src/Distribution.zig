const std = @import("std");
const Random = std.Random;

pub const VTable = struct {
    sample: *const fn (dist: *Distribution, rng: Random) f64,
};

pub const Distribution = @This();

vtable: *const VTable,

pub inline fn sample(self: *Distribution, rng: Random) f64 {
    return self.vtable.sample(self, rng);
}

// here should go common functions that behave the same for all the functionalities
// that is, for example, fill a buffer with n samples. samples has to be the implemented
// and the nSamples is here and just calls samples.




