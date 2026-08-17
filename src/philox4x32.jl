PhilioxReturnTypes = Union{UInt32, Float32, Float64}

struct Philox4x32 <: AbstractImmutableRNG
    key::UInt64
    counter::UInt64
end

# Bottom line: UInt32
function _counter_value(rng::Philox4x32, state::AbstractImmutableRNGState, ::Type{UInt32})
    u, _ = philox4x32_10(rng.counter, state.counter, rng.key)
    return u
end

function _counter_value(rng::Philox4x32, state::AbstractImmutableRNGState, ::Type{Float32})
    u, _ = randu01_f32(rng.counter, state.counter, rng.key)
    return u
end

function _counter_value(rng::Philox4x32, state::AbstractImmutableRNGState, ::Type{Float64})
    u, _ = randu01_f64(rng.counter, state.counter, rng.key)
    return u
end

@inline function ImmutableRNGs.rand_step(rng::Philox4x32, state::AbstractImmutableRNGState, ::Type{T} = Float64) where {T <: PhilioxReturnTypes}
    value = _counter_value(rng, state, T)
    return value, ImmutableRNGs.next_state(state)
end
