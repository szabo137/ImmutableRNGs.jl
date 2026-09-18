PhilioxReturnTypes = Union{UInt32, Float32, Float64}

"""
    Philox4x32(key, counter)

A Philox 4x32 RNG with 10 rounds, backed by `PhiloxRNG.jl`.

See Salmon et al., [*Parallel Random Numbers: As Easy as 1, 2, 3*](https://doi.org/10.1145/2063384.2063405).

Use directly with [`rand_step`](@ref). Supported sample types are `UInt32`,
`Float32`, and `Float64`.
"""
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
