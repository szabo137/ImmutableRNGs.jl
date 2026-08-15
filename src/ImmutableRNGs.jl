module ImmutableRNGs

using Random

export AbstractImmutableRNG, AbstractImmutableRNGState
export rand_step, rand_step!
export Splitmix64, CounterState
export StatefulRNG, stateful
## interface

"""
Marker supertype for immutable RNG backends.

The key design goal is that sampling does not mutate the RNG object itself.
Instead, every call consumes an explicit `state` value and returns the next
state together with the sample.
"""
abstract type AbstractImmutableRNG end

"""
Marker supertype for explicit RNG state objects.

For counter-based RNGs, the state may simply be an integer counter. For other
generators, it can be a struct containing the full internal state.
"""
abstract type AbstractImmutableRNGState end

function next_state end

"""
    rand_step(::AbstractImmutableRNG, state)

Interface function: return a tuple (sample, state), where `state` is the new state of the RNG.
"""
function rand_step end

function rand_step! end

## Backwards compat to Random

"""
Compatibility wrapper that exposes the legacy `Random.rand` API on top of the
immutable backend.

The wrapper owns the current state, but the underlying backend remains purely
functional.
"""
mutable struct StatefulRNG{R <: AbstractImmutableRNG, S} <: Random.AbstractRNG
    rng::R
    state::S
end

"""
Create a mutable compatibility wrapper from an immutable RNG and initial state.
"""
stateful(rng::R, state) where {R <: AbstractImmutableRNG} = StatefulRNG(rng, state)

"""
Legacy `Random.rand` compatibility layer.

All old-style calls are delegated to the immutable backend while the wrapper
stores the current state explicitly.
"""
function Random.rand(rng::StatefulRNG)
    sample, new_state = rand_step(rng.rng, rng.state)
    rng.state = new_state
    return sample
end

function Random.rand(rng::StatefulRNG, ::Type{T}) where {T}
    sample, new_state = rand_step(rng.rng, rng.state, T)
    rng.state = new_state
    return sample
end

function Random.rand(rng::StatefulRNG, dims::Dims)
    A = Array{Float64}(undef, dims)
    rng.state = rand_step!(A, rng.rng, rng.state, Float64)
    return A
end

function Random.rand(rng::StatefulRNG, ::Type{T}, dims::Dims) where {T}
    A = Array{T}(undef, dims)
    rng.state = rand_step!(A, rng.rng, rng.state, T)
    return A
end

Random.rand(rng::StatefulRNG, dims::Integer...) = Random.rand(rng, Tuple(dims))
Random.rand(rng::StatefulRNG, ::Type{T}, dims::Integer...) where {T} = Random.rand(rng, T, Tuple(dims))

function Random.rand!(rng::StatefulRNG, A::AbstractArray)
    rng.state = rand_step!(A, rng.rng, rng.state, eltype(A))
    return A
end

function Random.rand!(rng::StatefulRNG, A::AbstractArray, ::Type{T}) where {T}
    rng.state = rand_step!(A, rng.rng, rng.state, T)
    return A
end


## Simple counter state

struct CounterState <: AbstractImmutableRNGState
    counter::UInt64
end

next_state(state::CounterState) = CounterState(state.counter + 1)

# Reference Implementation: Splitmix64 (simple counter-based RNG)

"""
Reference counter-based RNG.

This backend demonstrates the intended API shape for counter-based generators:
the state is just a monotonically increasing counter, and each call maps the
current counter to output bits without mutating any hidden object state.
"""
struct Splitmix64 <: AbstractImmutableRNG
    seed::UInt64
end

@inline function splitmix64(x::UInt64)
    x += 0x9e3779b97f4a7c15
    z = x
    z = (z ⊻ (z >> 30)) * 0xbf58476d1ce4e5b9
    z = (z ⊻ (z >> 27)) * 0x94d049bb133111eb
    return z ⊻ (z >> 31)
end

@inline counter_value(rng::Splitmix64, state::CounterState) = splitmix64(state.counter + rng.seed)

# UInt64; bottom line
@inline function rand_step(rng::Splitmix64, state::CounterState, ::Type{UInt64})
    value = counter_value(rng, state)
    return value, next_state(state)
end

# Float64
@inline function rand_step(rng::Splitmix64, state::CounterState, ::Type{Float64})
    value, new_state = rand_step(rng, state, UInt64)
    sample = reinterpret(Float64, (value >> 12) | 0x3ff0000000000000) - 1.0
    return sample, new_state
end

# standard Integer
@inline function rand_step(rng::Splitmix64, state::CounterState, ::Type{Int})
    value, new_state = rand_step(rng, state, UInt64)
    return Int(value % UInt64(typemax(Int))), new_state
end

# default is Float64
@inline function rand_step(rng::Splitmix64, state::CounterState)
    return rand_step(rng, state, Float64)
end

function rand_step!(rng::Splitmix64, dest::AbstractArray{T}, state::CounterState) where {T}
    s = state
    @inbounds for i in eachindex(dest)
        dest[i], s = rand_step(rng, s, T)
    end
    return s
end


end
