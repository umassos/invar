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
	using JuMP, Ipopt
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

# ╔═╡ f72b8989-6713-46b4-b1d0-9e5327022397
euclidean_distance(p1, p2) = (p1[1] - p2[1])^2 + (p1[2] - p2[2])^2 |> sqrt

# ╔═╡ bfbce5ec-1269-4719-857f-4a64ab89e27a
service_rate = 10

# ╔═╡ 0b0b33d0-2b5b-473c-839e-b2f887d1d70f
arrival_rate_vector = fill(15, length(user_loc_positions))

# ╔═╡ 487b9867-f009-4ed9-b5e3-1b485fc70936
2.98078 * 8

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

# ╔═╡ f6c37148-ffd4-4d73-8b4d-95f4defcb67a
network_latency_matrix = [
	euclidean_distance(user_loc_pos, dc_pos) * cloud_to_user_latency
	for user_loc_pos in user_loc_positions, dc_pos in dc_positions
]

# ╔═╡ 0f83e05e-9aa3-4e82-8492-3ac72e2b2eeb
service_rate_vector = fill(service_rate, length(dc_positions))

# ╔═╡ 3a769d5f-33a4-44de-a59f-7f94327b9566
cloud_deployment = Int(ceil(sum(arrival_rate_vector) / 0.7 / service_rate_vector[1]))

# ╔═╡ 284048d7-74ce-41c9-ad1e-8a44b9e4a370
T_cloud = cloud_to_user_latency + 1 / service_rate_vector[1] + mean_waiting_time(cloud_deployment, sum(arrival_rate_vector), service_rate_vector[1])

# ╔═╡ fe0d2cce-3e0f-4ff8-8be1-680532648845
server_cost_vector = fill(1, length(dc_positions))

# ╔═╡ 189cef48-93ab-49a2-a4bd-3241364e6b0d
max_capacity_vector = [50, fill(10, length(edge_dc_positions))...]

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

# ╔═╡ bfb45e34-8295-4aa0-af0b-41e3516b077c
perfOptScenario = PerfOptScenario(
	baseScenario,
	18
)

# ╔═╡ 6ed61b3e-d5b7-4f4a-b210-e7048b20b828
perf_opt(perfOptScenario)

# ╔═╡ 203342a3-3434-48c9-b231-2cb765cde3a9
budget = 19

# ╔═╡ 00f2cd28-05a8-4548-8c49-a4f432be7328
flowOptScenario = FlowOptScenario(
	baseScenario,
	[0, 9, 3, 7, 0]
)

# ╔═╡ 03d43f37-dfd8-43ed-a586-9022b1cd13d8
 objective_value(flow_opt(flowOptScenario)[1])

# ╔═╡ 81fff749-c0e9-4fa5-bbdc-a5457fad7992
δ = 0.1

# ╔═╡ 58c8bc12-12a9-439d-b5ee-43214852fabf
scenario = Scenario(
	baseScenario,
	T_cloud - δ,
	budget
)

# ╔═╡ 0bbd73ca-0304-449e-9c7c-8b8fa6489f0c
scenario.base.Tᴺ

# ╔═╡ a928ea87-b4cf-4b0c-ad07-66cf8f5c7a83
map(r->sort!(collect(zip(1:scenario.base.K, r)), by=x->x[2]), eachrow(scenario.base.Tᴺ))[1]

# ╔═╡ 18e64a32-81b2-4215-b1df-7072d9646c79
solution = solve(scenario, true)

# ╔═╡ e91c0425-604f-43a7-8b88-1b2a4a1675e3
sum(solution[2])

# ╔═╡ Cell order:
# ╠═dbc157e0-2579-11ee-35eb-639355cc0d8e
# ╠═2bdc9431-eae7-49a3-87ba-cca9c5355e24
# ╠═e1f5e7d6-bbdf-4ab3-bacb-7450edca082a
# ╠═a21534b0-96a6-4ad4-94f4-2e7b2dee91c0
# ╠═f6372760-ce31-4243-94af-6dd869d75bf2
# ╠═4116c56a-534e-463d-8536-8965df8850e1
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
# ╠═0bbd73ca-0304-449e-9c7c-8b8fa6489f0c
# ╠═a928ea87-b4cf-4b0c-ad07-66cf8f5c7a83
# ╠═bfb45e34-8295-4aa0-af0b-41e3516b077c
# ╠═487b9867-f009-4ed9-b5e3-1b485fc70936
# ╠═6ed61b3e-d5b7-4f4a-b210-e7048b20b828
# ╠═58c8bc12-12a9-439d-b5ee-43214852fabf
# ╠═18e64a32-81b2-4215-b1df-7072d9646c79
# ╠═d50ebf77-561d-4c10-aaf4-f744fdebc257
# ╠═203342a3-3434-48c9-b231-2cb765cde3a9
# ╠═00f2cd28-05a8-4548-8c49-a4f432be7328
# ╠═03d43f37-dfd8-43ed-a586-9022b1cd13d8
# ╠═81fff749-c0e9-4fa5-bbdc-a5457fad7992
# ╠═e91c0425-604f-43a7-8b88-1b2a4a1675e3
