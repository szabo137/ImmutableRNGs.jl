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
