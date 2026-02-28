# Distribution

Zig library that aims to implement various distribution related functions commonly used in statistics. Right now it just implements `Uniform` and `Exponential` number generation with single or double precision.

## Aims

1. Support widely used Continous Distributions: Normal, logNormal, Cauchy, Gamma, Weibull...
2. Support widely used Discrete Distributions: Geometrical, Binomial, Bernoulli, Poisson...
3. Add support for the usually common functions. In R terminology those would be:
  - rfunc: random number generation
  - qfunc: quartile $z_{\alpha/2}$
  - dfunc: theoretical density function $f(x)$
  - pfunc: cumulative density funciton $F(x)$

## Design

I think this problem is absolutely suited for an _Intrusive Interface_ polymorphism. All implementation of the interface `Distribution` must implement the same functions `pdf(), cdf(), sample(), ppf()`, but there might be functions that the implementes share the exact same code, such as `sampleBuffer`, which just calls `sample()` on loop, regarding of what sample is.

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

```
const ex: f32 = exp.sample(rng);
```

A slice of random number can be filled if using the interface like this:

```zig
var esample: [40]f32 = undefined;
dexp.sampleBuffer(&esample, rng);
```
