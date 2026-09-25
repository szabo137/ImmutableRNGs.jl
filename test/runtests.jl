using ImmutableRNGs
using Test
using Random
PARAM_RNG = Xoshiro(137)

RNGs = [
    (Splitmix64(123), [Float32, Float64, UInt64, UInt32, Int]),
    (Philox4x32(123, 1), [Float32, Float64, UInt64, UInt32, Int]),
]

N = rand(PARAM_RNG, 2:10)

@testset "RNG = $(typeof(base_rng))" for (base_rng, DTYPES) in RNGs

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

    @testset "bulk immutable generation" begin
        initial_state = CounterState(0)

        @testset "type = $T" for T in DTYPES
            dest = Vector{T}(undef, N)

            final_state = rand_step!(base_rng, initial_state, dest)

            # Scalar generation is the reference sequence.
            expected = Vector{T}(undef, length(dest))
            expected_state = initial_state
            for i in eachindex(expected)
                expected[i], expected_state = rand_step(base_rng, expected_state, T)
            end

            @test dest == expected
            @test final_state == expected_state
            @test initial_state == CounterState(0)  # input state remains immutable
        end

        @testset "empty destination" begin
            dest = Float64[]
            final_state = rand_step!(base_rng, initial_state, dest)

            @test isempty(dest)
            @test final_state == initial_state
        end
    end
end
