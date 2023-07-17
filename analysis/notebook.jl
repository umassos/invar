### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ de11dfc4-2259-11ee-085f-25ad31a91c69
let
	import Pkg
	Pkg.activate(".")
	using InvarAnalysis.Scenarios
	using InvarAnalysis.Optimizations
	using JuMP, Ipopt
end

# ╔═╡ 1197a3fb-2bda-4eaa-90cf-29ed7331c202
scenario = Scenarios.load_scenario("scenario.yml")

# ╔═╡ cbcbb58e-05b8-452f-9286-5410f82c667f
function binary_search(baseScenario::BaseScenario, target, left, right, ϵ)
	if right - left <= ϵ
		(left + right) / 2
	else
		mid = (left + right) / 2
		scenario = PerfOptScenario(
			baseScenario,
			mid
		)
		model = perf_opt(scenario)
		status = termination_status(model)
		if (status == OPTIMAL || status == LOCALLY_SOLVED) && objective_value(model) <= target
			right = mid
		else
			left = mid
		end
		binary_search(baseScenario, target, left, right, ϵ)
	end
end

# ╔═╡ d5d35b50-04bc-4b88-a5a7-ef7a393f179f
x = binary_search(scenario.base, scenario.performance_target, 0, scenario.budget, 0.1)

# ╔═╡ ab08d1e5-ef32-4024-9066-f7171d61c922
testScenario = PerfOptScenario(
	scenario.base,
	x
)

# ╔═╡ 16f0448a-db87-4429-ae78-e6292ce6803b
model = perf_opt(testScenario)

# ╔═╡ 52a014b1-1f35-443c-9c18-35aff70381e6
termination_status(model)

# ╔═╡ Cell order:
# ╠═de11dfc4-2259-11ee-085f-25ad31a91c69
# ╠═1197a3fb-2bda-4eaa-90cf-29ed7331c202
# ╠═cbcbb58e-05b8-452f-9286-5410f82c667f
# ╠═d5d35b50-04bc-4b88-a5a7-ef7a393f179f
# ╠═ab08d1e5-ef32-4024-9066-f7171d61c922
# ╠═16f0448a-db87-4429-ae78-e6292ce6803b
# ╠═52a014b1-1f35-443c-9c18-35aff70381e6
