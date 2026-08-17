## Simple counter state

struct CounterState <: AbstractImmutableRNGState
    counter::UInt64
end

next_state(state::CounterState) = CounterState(state.counter + 1)
