# Distributions

Zig library to sample from distributions, trying to be as performant as possible.

Distributions implemented:
- Continuous: Exponential, Uniform, Normal, Pareto. 
- Discrete: Categorical, Empirical Cumulative Distribution, Constant.

If you need a distribution which is not implemented just let me know and I'll help on getting the implementation going :)

## Features
* **Generic Precision**: Support for Single (f32) and Double (f64) precision at comptime for Continuous Distributions and probability computations in Discrete Distributions.
* **Arbitrary Data Types**: Discrete distributions (like Categorical and ECDF) can sample and return Zig type such as ints, floats, enums and bools.
* **Dual Polymorphism**: two approaches of polymorphism, choose from:
    * **Tagged Unions:** Zero-overhead, compiler-inlined dispatch for closed sets of distributions.
    * **Intrusive Interface:** Fully dynamic, user-extensible dispatch for runtime flexibility.
* **Immutable Zero-Allocations post-init:** Distributions just require allocations (_if they require it_ as use of arrays) on init, then the object is immutable and just to be sampled from.
* **Goodness-of-Fit**: Kolmogorov-Smirnov test implemented to test continuous distributions.

## Getting Started 
[_See `src/main.zig` for the code_]

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

You can generate numbers without using the `sample` from the interface like this if you want to save a line if you do not need polymorphism.

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

The idea on this design was to offer the maximum amount of flexibility possible. That's the rationale behind having the option of a complete runtime know distribution through a VTable such as `Distribution` ---I believe this is an Intrusive Interface pattern/design--- and at the same time the function to sample is accessible without the need to generalize not needed to sample from there. Of course, depends on the usage you need: a `Distribution` is generic and allows to runtime dynamic dispatch the results, while not using it allows the compiler to save a dereference to find the concrete implementation of the `sample` function.

Reinforcing the fexibility mantra, we have also another polymorphism approach: a `switch`, which is what `ContinuousDistribution` and `DiscreteDistribution` use.


**Virtual Functions and Bloating**

As the implementation grew, I saw myself implementing a very extensive VTable, with `pdf`, `cdf` and `inversecdf` as if this was a general puropose statistics library, both for the implementation of the Ziggurat algorithm and the Kolmogorov-Smirnov testing. For now, I want to keep this library focused on random sampling, and all the extra methods some distributions have won't have to be added in the VTable. The only trade-off this needed was to declare the argument `cdf` in `ksTestCont` as an `anytype` instead of a function pointer.


## Sampling Algorithms

The sampling algorithms used depend on the distribution implemented.

Continuous Distributions:
- Normal: ziggurat algorithm, and marsaglia (i think?) on case zero.
- Exponential: Ziggurat algorithm, and the inverse method for case zero.
- Pareto: we use the fact that P = x_m * e^(E/alpha) where E ~ exp(1), so it's ziggurat with some added cost due to the transformation.

Discrete Distribution:
- Empirical Cumulative: sorts and counts the numbers, and stores that to sample from it.
- Categorical: naive algorithm. There is to my knowledge some far better algorithms.

