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

@testset "Waiting time calculation" begin
    @test round(MmcQueue.mean_waiting_time(2, 4.0, 3.5), sigdigits=6) ≈ 0.138528
    @test round(MmcQueue.mean_waiting_time(3, 6.0, 3.0), sigdigits=6) ≈ 0.148148
    @test round(MmcQueue.mean_waiting_time(6, 10.0, 2.0), sigdigits=6) ≈ 0.293758
end
