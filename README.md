# Distribution

Zig library to sample from statistical distributions. Born out of my need of quick configs while building a Discrete Event Simulation.

Distributions implemented:
- Continuous: Exponential, Uniform, Normal. (also Hyperexponential, Hypoexponential and Erlang, but not tested)
- Discrete: Categorical, Empirical Cumulative Distribution.

## Features
* **Generic Precision**: Support for Single (f32) and Double (f64) precision at comptime for Continuous Distributions and probability computations in Discrete Distributions.
* **Arbitrary Data Types**: Discrete distributions (like Categorical and ECDF) can sample and return any Zig type such as ints, floats, enums and bools.
* **Dual Polymorphism**: two approaches of polymorphism, choose from:
    * **Tagged Unions:** Zero-overhead, compiler-inlined dispatch for closed sets of distributions.
    * **Intrusive Interface:** Fully dynamic, user-extensible dispatch for runtime flexibility.
* **Immutable Zero-Allocations post-init:** Distributions just require allocations (_if they require it_ as use of arrays) on init, then the object is immutable and just to be sampled with.
* **pdf $f(x)$ and cdf $F(x)$**: Implemented in Exponential and Normal distributions.
* **Goodness-of-Fit**: Kolmogorov-Smirnov test for both continuous distributions.

## Tutorial 
_[See `src/main.zig` for the code]_

Create a distribution as the following:

```zig
const stats = @import("stats");

// We aliase the types with the desired precision for brevity
const Unif = stats.Uniform(f32);
const Exp = stats.Exponential(f32);
const Dist = stats.Distribution(f32);

const seed = blk: {
    var os_seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&os_seed));
    break :blk os_seed;
};

var prng = std.Random.DefaultPrng.init(seed);
const rng = prng.random();

var exp: Exp = .init(2);  // lambda = 2
const dexp: *Dist = &exp.interface; //access the interface
const e: f32 = dexp.sample(rng);
```


You can generate numbers without using the `sample` from the interface like this if you want to save a line. This is useful if you just want a quick random number.

```zig
const ex: f32 = exp.sample(rng);
```

A slice of random number can be filled if using the interface like this:

```zig
var esample: [40]f32 = undefined;
dexp.sampleBuffer(&esample, rng);
```

## Examples

In the `examples` folders there are 5 examples showcasing features:
- `continous_distribution.zig`: Creates and samples from the Continous Distributions. Shows how to sample from an array implementing the interface `Distribution` with different types. 
-  `discrete_distribution.zig`: Creates and samples from Discrete Distributions. Analogous to `continous_distribution.zig`
- `union.zig`: Showcases how to initialize an array with the union `ContinousDistribution` and sample from it.
- `union_disc.zig`: Analogous as the `union.zig`, but showcases the `DataType` as an `enum` and numeric types.
- `union_json.zig`: Defines an struct with the union distributions and reads from a JSON to have an struct with different distributions, both continuous and discrete.

## Design

This library emerged to solve a very specific need: change the configuration of a Discrete Event Simulation without recompiling the code, that is, to provide dynamic runtime dispatch. I've landed (inspired by Writergate) to use an Intrusive Interface (`Distribution.zig`) with a vtable. That means, every distribution struct can be instantiated standalone, or with the pointer to a `Distribution`. This makes the Distribution Type generic at runtime, at the cost of dereferencing the vtable function pointer everytime sample its called.

To make it generic from a file, I also needed to implement Polymorphism from a Tagged Union, to be able to write a JSON config file. As discrete and continuous distributions are different, two unions are provided: `ContinousDistribution` and `DiscreteDistribution`. Every distribution that can be loaded from a JSON needs a custom load JSON method to avoid writing the `interface` parameter on the JSON.

**Virtual Functions: what to have**

My OOP instincts told me that the VTable should contain all the functions to provide always dynamic runtime dispatch. Fortunately, my gut told me it was a bad idea. To implement `cdf` for the Kolmogorov-Smirnov test I opted - as it will never be needed at runtime - to use `anytype` for the distribution parameter. All the reasoning was that I do not need that on my DES, and it just cluttered the design a lot. By using `anytype` the compiler enforces at compile time that the passed struct implements a `cdf` method, giving us complete type safety without the overhead of a VTable.

To implement other functions can be for sure interesting, but until not needed I am not going to do it! This is just a quick tangent to arrive to my destination better.

## TODO
1. `Distribution(Precision)` -> `Distribution(Precision, Sample)` to allow generalization of the second data type.
2. Related to 1, this involves changing all the structure and comparisons of both `Categorical` and `ECDF` to the `utils.zig` function. Needed to implement both
3. Change constant from Continuous to discrete, as it is really discrete.
4. Finish the CDF of empirical distributions.
