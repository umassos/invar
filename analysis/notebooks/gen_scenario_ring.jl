### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ dbc157e0-2579-11ee-35eb-639355cc0d8e
let
	using Pkg
	Pkg.activate("..")
	using Plots
	using InvarAnalysis.MmcQueue
	using InvarAnalysis.Scenarios
	using InvarAnalysis.Optimizations
	using JuMP, Ipopt, KNITRO
	using YAML
end

# ╔═╡ 2bdc9431-eae7-49a3-87ba-cca9c5355e24
user_location_count = 8

# ╔═╡ e1f5e7d6-bbdf-4ab3-bacb-7450edca082a
user_loc_positions = [
	(cos(α*2π), sin(α*2π)) 
	for α in 
	[i/user_location_count for i in 0:user_location_count-1]
]

# ╔═╡ a21534b0-96a6-4ad4-94f4-2e7b2dee91c0
cloud_to_user_latency = 0.030

# ╔═╡ f6372760-ce31-4243-94af-6dd869d75bf2
edge_to_user_latency = 0.001

# ╔═╡ 4116c56a-534e-463d-8536-8965df8850e1
edge_to_cloud_ratio = 1 - edge_to_user_latency / cloud_to_user_latency

# ╔═╡ d50ebf77-561d-4c10-aaf4-f744fdebc257
edge_dc_count = 4

# ╔═╡ b5174704-cf3b-435f-875c-6072b7f1f001
edge_dc_positions = [
	(cos(α * 2π) * edge_to_cloud_ratio, sin(α * 2π) * edge_to_cloud_ratio)
	for α in
	[i / edge_dc_count for i in 0:edge_dc_count-1]
]

# ╔═╡ 2b47eaf2-fc9c-40e6-9552-4ba9243e9598
dc_positions = [(0,0), edge_dc_positions...]

# ╔═╡ 66b44303-0459-4008-a7e0-e995304a156e
let
	scatter(user_loc_positions, label="user locations", size=(500, 500))
	scatter!(dc_positions, label="data centers")
end

# ╔═╡ f72b8989-6713-46b4-b1d0-9e5327022397
euclidean_distance(p1, p2) = (p1[1] - p2[1])^2 + (p1[2] - p2[2])^2 |> sqrt

# ╔═╡ f6c37148-ffd4-4d73-8b4d-95f4defcb67a
network_latency_matrix = [
	euclidean_distance(user_loc_pos, dc_pos) * cloud_to_user_latency
	for user_loc_pos in user_loc_positions, dc_pos in dc_positions
]

# ╔═╡ bfbce5ec-1269-4719-857f-4a64ab89e27a
service_rate = 10

# ╔═╡ 0f83e05e-9aa3-4e82-8492-3ac72e2b2eeb
service_rate_vector = fill(service_rate, length(dc_positions))

# ╔═╡ fe0d2cce-3e0f-4ff8-8be1-680532648845
server_cost_vector = fill(1, length(dc_positions))

# ╔═╡ 0b0b33d0-2b5b-473c-839e-b2f887d1d70f
arrival_rate_vector = fill(15, length(user_loc_positions))

# ╔═╡ 3a769d5f-33a4-44de-a59f-7f94327b9566
cloud_deployment = Int(ceil(sum(arrival_rate_vector) / 0.7 / service_rate_vector[1]))

# ╔═╡ 189cef48-93ab-49a2-a4bd-3241364e6b0d
max_capacity_vector = [50, fill(10, length(edge_dc_positions))...]

# ╔═╡ 284048d7-74ce-41c9-ad1e-8a44b9e4a370
T_cloud = cloud_to_user_latency + 1 / service_rate_vector[1] + mean_waiting_time(cloud_deployment, sum(arrival_rate_vector), service_rate_vector[1])

# ╔═╡ 986a78a7-58af-4eb9-91e3-97fcf9dcd0e9
baseScenario = BaseScenario(
	user_location_count,
	arrival_rate_vector,
	length(dc_positions),
	max_capacity_vector,
	service_rate_vector,
	server_cost_vector,
	network_latency_matrix
)

# ╔═╡ 81fff749-c0e9-4fa5-bbdc-a5457fad7992
δ = 0.1

# ╔═╡ 658480bf-06d2-4bdf-890d-f91b406750fd
knitro = optimizer_with_attributes(
    KNITRO.Optimizer,
    "outlev" => 2,
    "algorithm" => 1,
    "ms_enable" => 1
)

# ╔═╡ 1b4c1542-ab60-4127-852f-e88898804864
flowOptScenario = FlowOptScenario(
	baseScenario,
	[0, 4, 5, 4, 5]
)

# ╔═╡ 547c2df8-4da6-477e-93ec-6bdcb489309b
flow_opt(flowOptScenario)

# ╔═╡ b5af5710-318d-4bb2-82a4-fc106b9beb0c
# ╠═╡ disabled = true
#=╠═╡
for budget in 18:24
	scenario = Scenario(
		baseScenario,
		T_cloud - δ,
		budget
	)
	solution = solve(scenario, exact=true, perfOptimizer=knitro)
	YAML.write_file("$(budget)_knitro1.yml",
		Dict(
			"base" => Dict(
				"user_location_count" => baseScenario.L,
				"arrival_rate_vector" => baseScenario.γ,
				"data_center_count" => baseScenario.K,
				"max_capacity_vector" => baseScenario.C,
				"service_rate_vector" => baseScenario.μ,
				"server_cost_vector" => baseScenario.w,
				"network_latency_matrix" => eachrow(baseScenario.Tᴺ)
			),
			"calculated_performance" => solution[1],
			"allocation_vector" => solution[2],
			"forwarding_probability_matrix" => eachrow(solution[3])
		)
	)
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═dbc157e0-2579-11ee-35eb-639355cc0d8e
# ╠═2bdc9431-eae7-49a3-87ba-cca9c5355e24
# ╠═e1f5e7d6-bbdf-4ab3-bacb-7450edca082a
# ╠═a21534b0-96a6-4ad4-94f4-2e7b2dee91c0
# ╠═f6372760-ce31-4243-94af-6dd869d75bf2
# ╠═4116c56a-534e-463d-8536-8965df8850e1
# ╠═d50ebf77-561d-4c10-aaf4-f744fdebc257
# ╠═b5174704-cf3b-435f-875c-6072b7f1f001
# ╠═2b47eaf2-fc9c-40e6-9552-4ba9243e9598
# ╠═66b44303-0459-4008-a7e0-e995304a156e
# ╠═f72b8989-6713-46b4-b1d0-9e5327022397
# ╠═f6c37148-ffd4-4d73-8b4d-95f4defcb67a
# ╠═bfbce5ec-1269-4719-857f-4a64ab89e27a
# ╠═0f83e05e-9aa3-4e82-8492-3ac72e2b2eeb
# ╠═fe0d2cce-3e0f-4ff8-8be1-680532648845
# ╠═0b0b33d0-2b5b-473c-839e-b2f887d1d70f
# ╠═3a769d5f-33a4-44de-a59f-7f94327b9566
# ╠═189cef48-93ab-49a2-a4bd-3241364e6b0d
# ╠═284048d7-74ce-41c9-ad1e-8a44b9e4a370
# ╠═986a78a7-58af-4eb9-91e3-97fcf9dcd0e9
# ╠═81fff749-c0e9-4fa5-bbdc-a5457fad7992
# ╠═658480bf-06d2-4bdf-890d-f91b406750fd
# ╠═1b4c1542-ab60-4127-852f-e88898804864
# ╠═547c2df8-4da6-477e-93ec-6bdcb489309b
# ╠═b5af5710-318d-4bb2-82a4-fc106b9beb0c
