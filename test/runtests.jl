using ImmutableRNGs
using Test

RNGs = [
    (Splitmix64(123), [Float64, UInt64, Int]),
    (Philox4x32(123, 1), [Float32, Float64, UInt32]),
]

@testset "RNG = $(typeof(RNG[1]))" for RNG in RNGs
    base_rng = RNG[1]
    DTYPES = RNG[2]

    @testset "immutable primitives" begin

        state = CounterState(0)

        @testset "default" begin
            sample, new_state = rand_step(base_rng, state)
            @test sample isa Float64
            @test new_state != state

            RNG2 = deepcopy(base_rng)
            sample2, new_state2 = rand_step(RNG2, state)
            @test sample2 == sample
            @test new_state2 == new_state
        end

        @testset "type = $T" for T in DTYPES
            sample, new_state = rand_step(base_rng, state, T)
            @test sample isa T
            @test new_state != state

            RNG2 = deepcopy(base_rng)
            sample2, new_state2 = rand_step(RNG2, state, T)
            @test sample2 == sample
            @test new_state2 == new_state
        end
    end

    @testset "Legacy compatibility" begin

        @testset "default" begin
            ref_state = CounterState(0)
            wrapper_rng = stateful(base_rng, ref_state)
            sample = rand(wrapper_rng)

            ref_sample, new_state = rand_step(base_rng, ref_state)

            @test sample isa Float64
            @test sample == ref_sample
        end

        @testset "type = $T" for T in DTYPES
            ref_state = CounterState(0)
            wrapper_rng = stateful(base_rng, ref_state)
            sample = rand(wrapper_rng, T)

            ref_sample, new_state = rand_step(base_rng, ref_state, T)

            @test sample isa T
            @test sample == ref_sample
        end
    end
end
