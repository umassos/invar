module Scenarios
import YAML
export BaseScenario, FlowOptScenario, PerfOptScenario, Scenario, load_scenario

struct BaseScenario
    L::Int  # number of user locations
    γ::Vector{Float64}  # arrival rate vector
    K::Int  # number of data centers
    C::Vector{Int}  # data center capacity (the maximum number of servers that can be allocated) vector
    μ::Vector{Float64}  # service rate matrix
    w::Vector{Float64}  # server cost (weight) vector
    Tᴺ::Matrix{Float64}  # network latency matrix
end

struct Scenario
    base::BaseScenario
    performance_target::Float64
    budget::Float64
end

function load_scenario(filename::AbstractString)::Scenario
    values = YAML.load_file(filename)
    values_base = values["base"]

    base = BaseScenario(
        values_base["user_location_count"],
        values_base["arrival_rate_vector"],
        values_base["data_center_count"],
        values_base["max_capacity_vector"],
        values_base["service_rate_vector"],
        values_base["server_cost_vector"],
        transpose(reduce(hcat, values_base["network_latency_matrix"]))
    )

    Scenario(
        base,
        values["performance_target"],
        values["budget"],
    )
end

struct FlowOptScenario
    base::BaseScenario
    c::Vector{Int}  # server allocation vector
end

struct PerfOptScenario
    base::BaseScenario
    W::Float64  # budget
end
end
