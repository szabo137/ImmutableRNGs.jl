# ImmutableRNGs

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://szabo137.github.io/ImmutableRNGs.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://szabo137.github.io/ImmutableRNGs.jl/dev)
[![Test workflow status](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/szabo137/ImmutableRNGs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/szabo137/ImmutableRNGs.jl)
[![Docs workflow Status](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)

ImmutableRNGs is a lightweight package, that provides an explicit-state interface for random-number generation
in Julia. Instead of mutating an RNG object, sampling returns both a value and
the state required for the next sample.

This model is well suited to counter-based generators and parallel or GPU
workloads, where RNG state can be passed explicitly between computations.

## Installation

```julia
using Pkg
Pkg.add("ImmutableRNGs")
```

Then load the package:

```julia
using ImmutableRNGs
```

## Quick start

Create an RNG and an initial state, then pass the returned state to the next
call:

```julia
rng = Splitmix64(0x123456789abcdef0)
state = CounterState(0)

x, state = rand_step(rng, state)          # `Float64` by default
y, state = rand_step(rng, state, UInt64)
z, state = rand_step(rng, state, Float32)
```

To fill an array, use `rand_step!`. It mutates the destination array and
returns the state after the final sample:

```julia
values = Vector{Float32}(undef, 1_000)
state = rand_step!(rng, state, values)
```

The generated type is determined by the destination array:

```julia
dest = Vector{UInt64}(undef, 1_000)
state = rand_step!(rng, state, dest)

dest = Matrix{Int}(undef, 10, 10)
state = rand_step!(rng, state, dest)
```

## Interface

Each backend implements `rand_step` for an explicit state:

```julia
rand_step(rng, state)
rand_step(rng, state, T)
```

Both methods return:

```julia
sample, next_state
```

The mutating array form fills a destination array and returns only the
resulting state:

```julia
rand_step!(rng, dest, state)
```

The RNG object remains immutable; all progressing state is represented by the
explicit `state` value.

## Currently provided counter-based RNGs

- `Splitmix64`: a SplitMix64 counter-based RNG supporting `UInt64`, `Float64`,
  and `Int`.
- `Philox4x32`: a Philox 4x32-10 counter-based RNG, backed by
  [`PhiloxRNG.jl`](https://github.com/JuliaRandom/PhiloxRNG.jl), supporting
  `UInt32`, `Float32`, and `Float64`.

## Compatibility with `Random`

`StatefulRNG` wraps an immutable backend together with its current state,
allowing use through Julia's conventional `Random.rand` interface:

```julia
stateful_rng = StatefulRNG(rng, CounterState(0))

rand(stateful_rng)
rand(stateful_rng, Float64)
rand!(stateful_rng, values)
```

The wrapper is mutable for compatibility, while the underlying backend retains
the explicit-state `rand_step` interface.

## Contributing

Contributions are welcome, especially additional RNG backends. Please open an
issue to discuss an idea or submit a pull request.

## Acknowledgements

This work was partly funded by the Center for Advanced Systems Understanding (CASUS) that
is financed by Germany’s Federal Ministry of Education and Research (BMBF) and by the Saxon
Ministry for Science, Culture and Tourism (SMWK) with tax funds on the basis of the budget
approved by the Saxon State Parliament.

We extend our gratitude for the support received through direct and indirect funding for this project, especially

- **Michael Bussmann**
- **Tobias Dornheim**

## AI assistance

Parts of the documentation and code were improved with assistance from
ChatGPT-5.6 Terra. All generated suggestions were reviewed and adapted by the
project authors.

## License

[MIT](LICENSE) © Uwe Hernandez Acosta
