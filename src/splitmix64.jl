# Reference Implementation: Splitmix64 (simple counter-based RNG)

"""
    Splitmix64(seed)

A SplitMix64 counter-based RNG.

See Steele, Lea, and Flood, [*Fast Splittable Pseudorandom Number
Generators*](https://doi.org/10.1145/2660193.2660195).

Use directly with [`rand_step`](@ref). Supported sample types are `UInt64`,
`Float64`, and `Int`.
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

# UInt32
@inline function rand_step(rng::Splitmix64, state::CounterState, ::Type{UInt32})
    value = counter_value(rng, state)
    return UInt32(value >> 32), next_state(state)
end

# Float64
@inline function rand_step(rng::Splitmix64, state::CounterState, ::Type{Float64})
    value, new_state = rand_step(rng, state, UInt64)
    sample = reinterpret(Float64, (value >> 12) | 0x3ff0000000000000) - 1.0
    return sample, new_state
end

# Float32
@inline function rand_step(rng::Splitmix64, state::CounterState, ::Type{Float32})
    value, new_state = rand_step(rng, state, UInt64)
    sample = reinterpret(Float32, UInt32(value >> 41) | 0x3f800000) - 1.0f0
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
