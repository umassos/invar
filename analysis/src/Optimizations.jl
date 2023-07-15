module Optimizations
using ..Scenarios
using JuMP, Ipopt
export flow_opt

function flow_opt(scenario::Scenarios.FlowOptScenario)
    model = Model(Ipopt.Optimizer)

    @expression(model, L, scenario.base.L)
    @expression(model, K, scenario.base.K)

    @variable(model, 0 <= p[1:L, 1:K] <= 1)

    @expressions(model, begin
        γ, scenario.base.γ
        Tᴺ, scenario.base.Tᴺ
        μ, scenario.base.μ
        c, scenario.c
        λ[j=1:K], sum(γ[i] * p[i, j] for i in 1:L)
        r[j=1:K], λ[j] / μ[j]
        ρ[j=1:K], r[j] / c[j]
    end)

    # precompute a factorial table since factorial will be computed multiple times
    max_server_count = maximum(scenario.c)
    @show max_server_count
    @expression(model, ft[i=0:max_server_count], factorial(big(i)))

    @NLexpression(
        model,
        P₀[j=1:K],
        (
            r[j]^c[j] / (ft[c[j]] * (1 - ρ[j])) +
            sum(r[j]^n / ft[n] for n in 0:c[j]-1)
        )^-1
    )

    # mean time spent by a request in each data center
    @NLexpression(
        model,
        Tᴰ[j=1:K],
        1 / μ[j] + (r[j]^c[j] / (ft[c[j]] * c[j] * μ[j] * (1 - ρ[j])^2)) * P₀[j]
    )

    @NLobjective(
        model,
        Min,
        sum(
            γ[i] * p[i, j] * (Tᴺ[i, j] + Tᴰ[j])
            for i in 1:L, j in 1:K
        ) / sum(γ[i] for i in 1:L)
    )

    @constraints(model, begin
        [i = 1:L], sum(p[i, j] for j in 1:K) == 1
        [j = 1:K], ρ[j] <= 0.99
    end)

    optimize!(model)
end
end
