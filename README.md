# Distributions

Random number sampling from distributions in and for Zig. Currently supports:

- **Continuous**: Exponential, Normal, Uniform, Pareto, Lognormal, Weibull, Gamma, ECDF, Constant.
- **Discrete**: Categorical, Empirical Cumulative Distribution Function (ECDF), DiscreteUniform, Constant.

## Examples

See [`examples/intro.zig`](examples/intro.zig) for a complete introduction.

Create and sample a distribution like this:

```zig
const std = @import("std");
const stats = @import("distributions");

const Exp = stats.Exponential(f32);
const Dist = stats.Distribution(f32);

pub fn main(init: std.process.Init) !void {
    const seed = blk: {
        var os_seed: u64 = undefined;
        init.io.random(std.mem.asBytes(&os_seed));
        break :blk os_seed;
    };

    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();

    const exp: Exp = .init(2); // lambda = 2
    const dexp: *const Dist = &exp.interface;
    const e: f32 = dexp.sample(rng);
    _ = e;
}
```

When polymorphism is not needed, sample directly:

```zig
const e: f32 = exp.sample(rng);
```

The interface can also fill a slice with samples:

```zig
var samples: [40]f32 = undefined;
dexp.sampleBuffer(&samples, rng);
```

The `examples` folder contains five examples:

- `intro.zig`: Basic Exponential and Normal sampling through the interface.
- `continous_distribution.zig`: Creates and samples continuous distributions, including an array of different distributions behind the `Distribution` interface.
- `discrete_distribution.zig`: Creates and samples concrete `Categorical` and `ECDF` distributions.
- `union.zig`: Initializes an array of `ContinuousDistribution` values and samples from it.
- `union_discrete.zig`: Demonstrates `ECDF` and `Categorical` with enum and numeric data types.

## Polymorphism

The library implements two types of polymorphism: runtime dynamic dispatch with an intrusive interface (VTable), and tagged-union switch dispatch.

### Intrusive interface

Every public distribution stores a `Distribution` interface. The interface provides `sample`, `format`, and the generic `sampleBuffer` helper without exposing the concrete distribution type.

The VTable currently contains only `sample` and `format`; `sampleBuffer` is implemented in terms of `sample`.

### Tagged union

`ContinuousDistribution` and `DiscreteDistribution` are tagged unions. Calling `sample` switches on the active variant and calls its concrete sampler. You can define similar unions outside the library for your own distribution categories.

## Sampling algorithms

Continuous distributions:

- **Normal and Exponential**: Ziggurat algorithm.
- **Pareto**: Inverse-CDF transform of an Exp(1) sample from this library's Ziggurat sampler.
- **Weibull**: Inverse-CDF transform of `std.Random.floatExp()`; std's exponential sampler also uses Ziggurat.
- **Lognormal**: Exponential transform of a Normal sample.
- **Gamma**: Marsaglia–Tsang rejection sampling, using a stored `Normal(Precision)` distribution.
- **Uniform**: Wrapper around `rng.float()` with open/closed interval sampling.
- **Constant**: Always returns its configured value.
- **ECDF**: Sorts and counts the input, stores cumulative probabilities, and samples by binary search.

Discrete distributions:

- **ECDF**: Sorts and counts the input, stores cumulative probabilities, and samples by binary search.
- **Categorical**: Linear scan over cumulative weights.
- **DiscreteUniform**: Wrapper around `rng.intRangeAtMost()` with open/closed interval sampling.
- **Constant**: Always returns its configured value.

Missing a distribution? PR it or let me know :)

## Use

Tested version is `0.16.0`. `master` will be updated as the versions advance. Add this as a dependency with the following command:

```
$ zig fetch git+https://github.com/PauSolerValades/distributions.git    
```

