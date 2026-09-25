module ImmutableRNGs

using Random
using PhiloxRNG

export AbstractImmutableRNG, AbstractImmutableRNGState
export rand_step, rand_step!
export randn_step, randn_step!
export StatefulRNG, stateful
export Splitmix64, CounterState
export Philox4x32
## interface

"""
    AbstractImmutableRNG

Abstract supertype for immutable random-number generator backends.

Use [`rand_step`](@ref) with an explicit RNG state to generate samples.
"""
abstract type AbstractImmutableRNG end


"""
    AbstractImmutableRNGState

Abstract supertype for explicit immutable RNG states.
"""
abstract type AbstractImmutableRNGState end

"""
    next_state(state)

Return the state following `state`.
"""
function next_state end

"""
    rand_step(rng, state)
    rand_step(rng, state, T)

Generate a sample from `rng` using `state`, returning `(sample, next_state)`.
"""
function rand_step end

"""
    randn_step(rng, state)
    randn_step(rng, state, T)

Generate a normally distributed sample from `rng` using `state`, returning
`(sample, next_state)`.
"""
function randn_step end

@inline function randn_step(
        rng::AbstractImmutableRNG,
        state::AbstractImmutableRNGState,
    )
    return randn_step(rng, state, Float64)
end

@inline function randn_step(
        rng::AbstractImmutableRNG,
        state::AbstractImmutableRNGState,
        ::Type{T},
    ) where {T <: Union{Float32, Float64}}
    u1, state = rand_step(rng, state, T)
    u2, state = rand_step(rng, state, T)

    radius = sqrt(-T(2) * log1p(-u1))
    angle = T(2π) * u2

    return radius * cos(angle), state
end
"""
    rand_step!(rng, state, dest)

Fill `dest` with samples from `rng`, starting at `state`, and return the
resulting state.
"""
function rand_step! end

# generic implementation
function rand_step!(rng::AbstractImmutableRNG, state::AbstractImmutableRNGState, dest::AbstractArray{T}) where {T}
    s = state
    @inbounds for i in eachindex(dest)
        dest[i], s = rand_step(rng, s, T)
    end
    return s
end

"""
    randn_step!(rng, state, dest)

Fill `dest` with normally distributed samples from `rng` using `state`, and
return the state after the final sample.
"""
function randn_step! end

function randn_step!(
        rng::AbstractImmutableRNG,
        state::AbstractImmutableRNGState,
        dest::AbstractArray{T},
    ) where {T <: Union{Float32, Float64}}
    s = state

    @inbounds for i in eachindex(dest)
        dest[i], s = randn_step(rng, s, T)
    end

    return s
end

include("random.jl")
include("counter_state.jl")
include("splitmix64.jl")
include("philox4x32.jl")

end
