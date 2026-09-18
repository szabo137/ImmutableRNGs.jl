## Simple counter state
"""
    CounterState(counter)

Immutable counter-based RNG state.
"""
struct CounterState <: AbstractImmutableRNGState
    counter::UInt64
end

"""
    next_state(state::CounterState)

Return `state` with its counter incremented by one.
"""
next_state(state::CounterState) = CounterState(state.counter + 1)
