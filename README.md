# ImmutableRNGs

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://szabo137.github.io/ImmutableRNGs.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://szabo137.github.io/ImmutableRNGs.jl/dev)
[![Test workflow status](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/szabo137/ImmutableRNGs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/szabo137/ImmutableRNGs.jl)
[![Docs workflow Status](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/szabo137/ImmutableRNGs.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

This package drafts a backend-oriented random-number interface for Julia where sampling
explicitely returns the state:

```Julia
sample, new_state = rand_step(rng,  state)
```

Main goals:

- support GPU-friendly usage patterns by making the RNG object immutable,
- support counter-based generators naturally, where the state is a counter,
- keep the `Random.rand` API available through a thin compatibility layer.

## Draft interface

### Core primitives

Implement these methods for each backend:

```julia
rand_step(rng::MyRNG, state)
rand_step(rng::MyRNG, state, ::Type{T})
rand_step!(dest, rng::MyRNG, state)
rand_step!(dest, rng::MyRNG, state, ::Type{T})
```

where the interface is:

- `rand_step` returns `(sample, new_state)`,
- `rand_step!` fills `dest` in place and returns `new_state`,
- `state` is an explicit value, not hidden inside `rng`.

### Compatibility layer

`StatefulRNG` is a small mutable wrapper that stores the current state and
forwards legacy `Random.rand` calls to the immutable primitive.

This lets existing code keep calling:

```julia
rand(stateful_rng)
rand(stateful_rng, Float64)
rand!(stateful_rng, A)
```

while the actual backend remains state-explicit.

## Design notes and open questions

There are a few places where the design still deserves product-level decisions:

1. Should `rand_step` be the canonical name, or should the package expose a more
   generic trait-based name like `rand_stateful` or `randnext`?
2. Should the state type be required to be a separate type from the RNG type,
   or should small immutable RNGs be allowed to carry the whole state in a
   single object that is threaded through unchanged?
3. How should seeding work across backends so that `seed -> initial state` is
   normalized?
4. For GPU use, do we want the explicit state to be a scalar, a struct, or an
   array depending on backend?
5. For GPU, do we manage the distribution of counters using shared memory?
