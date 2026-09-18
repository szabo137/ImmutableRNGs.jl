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


include("random.jl")
include("counter_state.jl")
include("splitmix64.jl")
include("philox4x32.jl")

end
