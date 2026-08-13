using ImmutableRandom
using Test

@testset "ImmutableRandom.jl" begin
    @test ImmutableRandom.hello_world() == "Hello, World!"
end
