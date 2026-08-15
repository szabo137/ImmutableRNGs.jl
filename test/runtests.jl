using ImmutableRNGs
using Test

DTYPES = [Float64, UInt64, Int]

@testset "immutable primitives" begin

    RNG = Splitmix64(123)
    state = CounterState(0)

    @testset "default" begin
        sample, new_state = rand_step(RNG, state)
        @test sample isa Float64
        @test new_state != state

        RNG2 = deepcopy(RNG)
        sample2, new_state2 = rand_step(RNG2, state)
        @test sample2 == sample
        @test new_state2 == new_state
    end

    @testset "type = $T" for T in DTYPES
        sample, new_state = rand_step(RNG, state, T)
        @test sample isa T
        @test new_state != state

        RNG2 = deepcopy(RNG)
        sample2, new_state2 = rand_step(RNG2, state, T)
        @test sample2 == sample
        @test new_state2 == new_state
    end
end

@testset "Legacy compatibility" begin
    base_rng = Splitmix64(137)

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
