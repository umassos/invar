using InvarAnalysis
using Test

@testset "Erlang C calculation" begin
    @test round(MmcQueue.erlang_c(2, 1.0), sigdigits=5) ≈ 0.33333
    @test round(MmcQueue.erlang_c(20, 16.0), sigdigits=5) ≈ 0.25608
end

@testset "Erlang C upper bound" begin
    @test round(MmcQueue.erlang_c_ub(2, 1.0), sigdigits=5) ≈ 0.33936
    @test round(MmcQueue.erlang_c_ub(20, 16.0), sigdigits=5) ≈ 0.25663
end
