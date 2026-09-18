module ImmutableRNGs

using Random
using PhiloxRNG

export AbstractImmutableRNG, AbstractImmutableRNGState
export rand_step, rand_step!
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
    rand_step!(rng, dest, state)

Fill `dest` with samples from `rng`, starting at `state`, and return the
resulting state.
"""
function rand_step! end


include("random.jl")
include("counter_state.jl")
include("splitmix64.jl")
include("philox4x32.jl")

end
