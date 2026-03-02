# Distribution

Zig library to sample from statistical distributions. Born out of my need of quick configs while building a Discrete Event Simulation.

Distributions implemented:
- Continuous: Exponential, Uniform. (also Hyperexponential, Hypoexponential and Erlang, but not tested)
- Discrete: Categorical, Empirical Cumulative Distribution.

## Features
* **Generic Precision**: Support for Single (f32) and Double (f64) precision at comptime for Continuous Distributions and probability computations in Discrete Distributions.
* **Arbitrary Data Types**: Discrete distributions (like Categorical and ECDF) can sample and return any Zig type such as ints, floats, enums and bools.
* **Dual Polymorphism**: two approaches of polymorphism, choose from:
    * **Tagged Unions:** Zero-overhead, compiler-inlined dispatch for closed sets of distributions.
    * **Intrusive Interfaces:** Fully dynamic, user-extensible dispatch for runtime flexibility.
* **Immutable Zero-Allocations post-init:** Distributions just require allocations (_if they require it_ as use of arrays) on init, then the object is immutable and just to be sampled with.

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
- `discrete_distribution.zig`: Creates and samples from Discrete Distributions. Analogous to `continous_distribution.zig`
- `union.zig`: Showcases how to initialize an array with the union `ContinousDistribution` and sample from it.
- `union_disc.zig`: Analogous as the `union.zig`, but showcases the `DataType` as an `enum` and numeric types.
- `union_json.zig`: Defines an struct with the union distributions and reads from a JSON to have an struct with different distributions, both continuous and discrete.


## Aims

1. Support widely used Continous Distributions: Normal, logNormal, Cauchy, Gamma, Weibull...
2. Support widely used Discrete Distributions: Geometrical, Binomial, Bernoulli, Poisson...
3. Add support for the usually common functions, despite it's main focus should be just sampling. In R terminology those would be:
  - rfunc: random number generation
  - qfunc: quartile $z_{\alpha/2}$
  - dfunc: theoretical density function $f(x)$
  - pfunc: cumulative density funciton $F(x)$

## Design

I think this problem is absolutely suited for an _Intrusive Interface_ polymorphism. All implementation of the interface `Distribution` must implement the same functions `pdf(), cdf(), sample(), ppf()`, but there might be functions that the implementes share the exact same code, such as `sampleBuffer`, which just calls `sample()` on loop, regarding of what sample is.

Regarding the Union, it's also a useful to make the polymorphism at run time, eg, reading from a JSON config to know what to sample to.


