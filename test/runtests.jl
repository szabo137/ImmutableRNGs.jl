using ImmutableRNGs
using Test

@testset "ImmutableRNGs.jl" begin
    @test ImmutableRNGs.hello_world() == "Hello, World!"
end
