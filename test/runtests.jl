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

        @testset "uniformly distributed" begin

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

        @testset "normal distributed" begin
            state = CounterState(0)

            @testset "default" begin
                sample, new_state = randn_step(base_rng, state)

                @test sample isa Float64
                @test isfinite(sample)
                @test new_state != state

                rng2 = deepcopy(base_rng)
                sample2, new_state2 = randn_step(rng2, state)

                @test sample2 == sample
                @test new_state2 == new_state
            end

            @testset "type = $T" for T in (Float32, Float64)
                sample, new_state = randn_step(base_rng, state, T)

                @test sample isa T
                @test isfinite(sample)
                @test new_state != state

                _, expected_state = rand_step(base_rng, state, T)
                _, expected_state = rand_step(base_rng, expected_state, T)
                @test new_state == expected_state

                rng2 = deepcopy(base_rng)
                sample2, new_state2 = randn_step(rng2, state, T)

                @test sample2 == sample
                @test new_state2 == new_state
            end
        end
    end

    @testset "bulk generation" begin

        @testset "normal distributed" begin
            initial_state = CounterState(0)

            @testset "type = $T" for T in (Float32, Float64)
                dest = Vector{T}(undef, 7)

                final_state = randn_step!(base_rng, initial_state, dest)

                # Repeated scalar generation is the reference sequence.
                expected = Vector{T}(undef, length(dest))
                expected_state = initial_state
                for i in eachindex(expected)
                    expected[i], expected_state = randn_step(base_rng, expected_state, T)
                end

                @test dest == expected
                @test all(isfinite, dest)
                @test final_state == expected_state
                @test initial_state == CounterState(0)
            end

            @testset "empty destination" begin
                dest = Float64[]

                final_state = randn_step!(base_rng, initial_state, dest)

                @test isempty(dest)
                @test final_state == initial_state
            end
        end


        @testset "uniformly distributed" begin
            initial_state = CounterState(0)

            @testset "type = $T" for T in DTYPES
                dest = Vector{T}(undef, N)

                final_state = rand_step!(base_rng, initial_state, dest)

                expected = Vector{T}(undef, length(dest))
                expected_state = initial_state
                for i in eachindex(expected)
                    expected[i], expected_state = rand_step(base_rng, expected_state, T)
                end

                @test dest == expected
                @test final_state == expected_state
                @test initial_state == CounterState(0)
            end

            @testset "empty destination" begin
                dest = Float64[]
                final_state = rand_step!(base_rng, initial_state, dest)

                @test isempty(dest)
                @test final_state == initial_state
            end
        end
    end

    @testset "Legacy compatibility" begin

        @testset "rand" begin

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
        @testset "rand!" begin
            initial_state = CounterState(0)

            @testset "type = $T" for T in DTYPES
                wrapper_rng = stateful(base_rng, initial_state)
                dest = Vector{T}(undef, N)

                rand!(wrapper_rng, dest)

                expected = Vector{T}(undef, length(dest))
                expected_state = initial_state
                for i in eachindex(expected)
                    expected[i], expected_state = rand_step(base_rng, expected_state, T)
                end

                @test dest == expected

                next_sample = rand(wrapper_rng, T)
                expected_next, _ = rand_step(base_rng, expected_state, T)
                @test next_sample == expected_next
            end

            @testset "empty destination" begin
                wrapper_rng = stateful(base_rng, initial_state)
                dest = Float64[]

                rand!(wrapper_rng, dest)

                @test isempty(dest)

                sample = rand(wrapper_rng)
                expected, _ = rand_step(base_rng, initial_state)
                @test sample == expected
            end
        end
        @testset "randn" begin
            initial_state = CounterState(0)

            @testset "scalar default" begin
                wrapper_rng = stateful(base_rng, initial_state)

                sample = randn(wrapper_rng)
                expected, expected_state = randn_step(base_rng, initial_state)

                @test sample isa Float64
                @test sample == expected

                next_sample = randn(wrapper_rng)
                expected_next, _ = randn_step(base_rng, expected_state)
                @test next_sample == expected_next
            end

            @testset "scalar type = $T" for T in (Float32, Float64)
                wrapper_rng = stateful(base_rng, initial_state)

                sample = randn(wrapper_rng, T)
                expected, expected_state = randn_step(base_rng, initial_state, T)

                @test sample isa T
                @test sample == expected

                next_sample = randn(wrapper_rng, T)
                expected_next, _ = randn_step(base_rng, expected_state, T)
                @test next_sample == expected_next
            end

            @testset "array type = $T" for T in (Float32, Float64)
                wrapper_rng = stateful(base_rng, initial_state)

                samples = randn(wrapper_rng, T, N, N + 2)

                expected = Matrix{T}(undef, N, N + 2)
                expected_state = initial_state
                for i in eachindex(expected)
                    expected[i], expected_state = randn_step(base_rng, expected_state, T)
                end

                @test samples == expected
                @test all(isfinite, samples)

                next_sample = randn(wrapper_rng, T)
                expected_next, _ = randn_step(base_rng, expected_state, T)
                @test next_sample == expected_next
            end

            @testset "randn! type = $T" for T in (Float32, Float64)
                wrapper_rng = stateful(base_rng, initial_state)
                dest = Vector{T}(undef, N)

                result = randn!(wrapper_rng, dest)

                expected = Vector{T}(undef, length(dest))
                expected_state = initial_state
                for i in eachindex(expected)
                    expected[i], expected_state = randn_step(base_rng, expected_state, T)
                end

                @test result === dest
                @test dest == expected
                @test all(isfinite, dest)

                next_sample = randn(wrapper_rng, T)
                expected_next, _ = randn_step(base_rng, expected_state, T)
                @test next_sample == expected_next
            end

            @testset "randn! empty destination" begin
                wrapper_rng = stateful(base_rng, initial_state)
                dest = Float64[]

                randn!(wrapper_rng, dest)

                @test isempty(dest)

                sample = randn(wrapper_rng)
                expected, _ = randn_step(base_rng, initial_state)
                @test sample == expected
            end
        end
    end
end
