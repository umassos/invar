module Scenarios
import YAML
export FlowOptScenario, Scenario, load_scenario

struct BaseScenario
    L::Int  # number of user locations
    γ::Vector{Float64}  # arrival rate vector
    K::Int  # number of data centers
    W::Vector{Int}  # data center capacity (the maximum number of servers that can be allocated) vector
    N::Matrix{Float64}  # network latency matrix
    μ::Vector{Float64}  # service rate matrix
    c::Vector{Float64}  # server cost vector
end

struct Scenario
    base::BaseScenario
    T_cloud::Float64  # mean response time under the cloud deployment
    ϵ::Float64  # target improvement over T_cloud
    C_cloud::Float64  # overall server cost under the cloud deployment
    α::Float64  # budget ratio
end

function load_scenario(filename::AbstractString)::Scenario
    values = YAML.load_file(filename)
    values_base = values["base"]

    base = BaseScenario(
        values_base["user_location_count"],
        values_base["arrival_rate_vector"],
        values_base["data_center_count"],
        values_base["max_capacity_vector"],
        transpose(reduce(hcat, values_base["network_latency_matrix"])),
        values_base["service_rate_vector"],
        values_base["server_cost_vector"]
    )

    Scenario(
        base,
        values["mean_response_time_cloud"],
        values["target_improvement"],
        values["overall_server_cost_cloud"],
        values["budget_ratio"],
    )
end

struct FlowOptScenario
    base::BaseScenario
    w::Vector{Int}  # server allocation vector
end
end
