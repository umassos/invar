module Optimizations
using ..MmcQueue
using ..Scenarios
using JuMP, Ipopt
export flow_opt, perf_opt, solve

function flow_opt(scenario::FlowOptScenario)
    model = Model(Ipopt.Optimizer)

    # remove empty data centers in the scenario because their P₀ cannot be computed
    non_empty_indices = findall(scenario.c .> 0)
    @expression(model, L, scenario.base.L)
    @expression(model, K, length(non_empty_indices))

    @variable(model, 0 <= p[1:L, 1:K] <= 1)

    @expressions(model, begin
        γ, scenario.base.γ
        Tᴺ, scenario.base.Tᴺ[:, non_empty_indices]
        μ, scenario.base.μ[non_empty_indices]
        c, scenario.c[non_empty_indices]
        λ[j=1:K], sum(γ[i] * p[i, j] for i in 1:L)
        r[j=1:K], λ[j] / μ[j]
        ρ[j=1:K], r[j] / c[j]
    end)

    # precompute a factorial table since factorial will be computed multiple times
    max_server_count = maximum(c)
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

    # @NLexpression(
    # 	model,
    # 	t[j=1:K],
    # 	(r[j]^c[j]) / (ft[c[j]] * (1 - r[j] / c[j]))
    # )

    # @NLexpression(
    # 	model,
    # 	erlang_c[j=1:K],
    # 	t[j] / (t[j] + sum(r[j]^n / ft[n] for n in 0:c[j]-1))
    # )

    # @NLexpression(
    # 	model,
    # 	Tᴰ[j=1:K],
    # 	1/λ[j] * erlang_c[j] * ρ[j] / (1 - ρ[j]) + 1 / μ[j]
    # )

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
    p_value = zeros(scenario.base.L, scenario.base.K)
    p_value[:, non_empty_indices] = value.(p)
    model, p_value
end

# Heuristics for calculating a starting value for c and p.
function calculate_starting_values(scenario::PerfOptScenario)
    if scenario.budget > sum(scenario.base.C)
        error("budget is greater than all available capacity")
    end
    ρ = sum(scenario.base.γ) / scenario.budget
    residual_arrival_rates = copy(scenario.base.γ)
    Tᴺ_sorted = map(
        r -> sort!(collect(zip(1:scenario.base.K, r)), by=x -> x[2]),
        eachrow(scenario.base.Tᴺ)
    )
    c_value = zeros(scenario.base.K)
    p_value = zeros(scenario.base.L, scenario.base.K)
    while true
        (residual, user_loc_index) = findmax(residual_arrival_rates)
        if residual == 0
            break
        end
        servers_required = residual / ρ
        for (dc_index, _) in Tᴺ_sorted[user_loc_index]
            servers_available = scenario.base.C[dc_index] - c_value[dc_index]
            if servers_available > 0
                servers_allocated = min(servers_required, servers_available)
                c_value[dc_index] += servers_allocated
                requests_served = servers_allocated * ρ
                residual_arrival_rates[user_loc_index] -= servers_allocated * ρ
                p_value[user_loc_index, dc_index] += requests_served
                break
            end
        end
    end
    p_value = p_value ./ scenario.base.γ
    c_value, p_value
end

function perf_opt(scenario::PerfOptScenario)
    model = Model(Ipopt.Optimizer)
    # set_optimizer_attribute(model, "max_iter", 5000)

    @expression(model, L, scenario.base.L)
    @expression(model, K, scenario.base.K)
    @expression(model, C, scenario.base.C)

    c_starting_value, p_starting_value = calculate_starting_values(scenario)
    @variable(model, 0 <= c[j=1:K] <= C[j], start = c_starting_value[j])
    @variable(model, 0 <= p[i=1:L, j=1:K] <= 1, start = p_starting_value[i, j])
    # @variable(model, 0 <= c[j=1:K] <= C[j])
    # @variable(model, 0 <= p[i=1:L, j=1:K] <= 1)

    @expressions(model, begin
        γ, scenario.base.γ
        μ, scenario.base.μ
        w, scenario.base.w
        Tᴺ, scenario.base.Tᴺ
        W, min(scenario.budget, sum(scenario.base.C))
        λ[j=1:K], sum(γ[i] * p[i, j] for i in 1:L)
        r[j=1:K], λ[j] / μ[j]
    end)

    JuMP.register(
        model,
        :erlang_c_ub,
        2,
        erlang_c_ub,
        autodiff=true
    )

    @NLexpression(
        model,
        Tᴰ[j=1:K],
        erlang_c_ub(c[j] + 1e-5, r[j] + 1e-5) / (c[j] * μ[j] - λ[j] + 1e-5) + 1 / μ[j]
    )

    @NLexpression(
        model,
        T,
        sum(
            γ[i] * p[i, j] * (Tᴺ[i, j] + Tᴰ[j])
            for i in 1:L, j in 1:K
        ) / sum(γ[i] for i in 1:L)
    )

    @NLobjective(
        model,
        Min,
        T + 0.1 * (sum(c[j] * w[j] for j in 1:K) - W)^2
    )

    @constraints(model, begin
        [j = 1:K], λ[j] <= 0.99 * c[j] * μ[j]
        [i = 1:L], sum(p[i, j] for j in 1:K) == 1
    end)

    optimize!(model)
    model, value(T), value.(c), value.(λ)
end

acceptable_statuses = [OPTIMAL, ALMOST_OPTIMAL, LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]

function binary_search(baseScenario::BaseScenario, target, left, right, ϵ)
    if right - left <= ϵ
        right
    else
        mid = (left + right) / 2
        scenario = PerfOptScenario(
            baseScenario,
            mid
        )
        model, T, c, λ = perf_opt(scenario)
        status = termination_status(model)
        @show left, mid, right, T, status
        if status in acceptable_statuses && T <= target
            @show T
            right = mid
        else
            left = mid
        end
        binary_search(baseScenario, target, left, right, ϵ)
    end
end

function solve(scenario::Scenario, exact::Bool=false)
    base = scenario.base
    x = binary_search(
        base,
        scenario.performance_target,
        0,
        scenario.budget,
        0.1
    )

    perfOptscenario = PerfOptScenario(
        base,
        x
    )
    model, T, c, λ = perf_opt(perfOptscenario)
    if T > scenario.performance_target
        println(stderr, "could not find a solution with in budget")
    end
    @show c, λ

    c_lowerbound = map(x -> x < 0 ? 0 : Int(floor(x)), c)
    candidates = [c_lowerbound]
    diff_with_indices = collect(zip(c - c_lowerbound, 1:scenario.base.K))
    sort!(diff_with_indices, rev=true)
    for (diff, index) in diff_with_indices
        if diff <= 0
            break
        end
        candidate = copy(last(candidates))
        if candidate[index] + 1 <= scenario.base.C[index]
            candidate[index] += 1
            push!(candidates, candidate)
        end
    end
    @show candidates

    if exact
        i = findfirst(c -> sum(c) >= scenario.budget, candidates)
        solution = candidates[i]
        flowOptScenario = FlowOptScenario(
            scenario.base,
            solution
        )
        model, p = flow_opt(flowOptScenario)
        return objective_value(model), solution, p
    else
        for (i, candidate) in enumerate(candidates)
            flowOptScenario = FlowOptScenario(
                scenario.base,
                candidate
            )
            model, p = flow_opt(flowOptScenario)

            status = termination_status(model)
            solved = (
                status in acceptable_statuses && objective_value(model) <= scenario.performance_target
            )
            if solved || i == length(candidates)
                return objective_value(model), candidate, p
            end
        end
    end
end
end
