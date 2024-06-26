import os
import sys

import numpy as np
from numpy.random import SeedSequence, default_rng
from simpy import Environment
from simpy.resources.resource import PriorityResource

from lb import LoadBalancer
from predef import DataCenterId, UserLocId
from request import RequestGenerator
from rng import ChoiceRNG, ExponentialRNG, RNG
from scenario import *

if __name__ == "__main__":
    if len(sys.argv) == 2:
        filename = sys.argv[1]
        ss = SeedSequence()
    elif len(sys.argv) == 3:
        filename = sys.argv[1]
        ss = SeedSequence(int(sys.argv[2]))
    else:
        print(f"usage: {sys.argv[0]} scenario_file [seed]")
        exit(os.EX_USAGE)

    scenario = load_simulation_scenario(filename)

    env = Environment()

    iat_gen_seeds = ss.spawn(scenario.base.user_location_count)
    user_loc_to_iat_gen: dict[UserLocId, RNG] = {
        UserLocId(i + 1): ExponentialRNG(scenario.base.arrival_rate_vector[i], default_rng(iat_gen_seeds[i]))
        for i in range(scenario.base.user_location_count)
    }

    st_gen_seeds = ss.spawn(scenario.base.data_center_count)
    dc_to_st_gen: dict[DataCenterId, RNG] = {
        DataCenterId(i + 1): ExponentialRNG(scenario.base.service_rate_vector[i], default_rng(st_gen_seeds[i]))
        for i in range(scenario.base.data_center_count)
    }

    dc_to_servers = {}
    for i in range(scenario.base.data_center_count):
        allocated_capacity = scenario.allocation_vector[i]
        dc_to_servers[DataCenterId(i + 1)] = (
            PriorityResource(env, capacity=scenario.allocation_vector[i]) if allocated_capacity > 0 else None
        )

    selectors = []
    selector_seeds = ss.spawn(scenario.base.user_location_count)
    for i, row in enumerate(scenario.forwarding_probability_matrix):
        selector = ChoiceRNG(
            choices=[DataCenterId(j + 1) for j in range(scenario.base.data_center_count)],
            probabilities=row,
            generator=default_rng(selector_seeds[i]),
        )
        selectors.append(selector)

    user_loc_to_selectors = {UserLocId(i + 1): selectors[i] for i in range(scenario.base.user_location_count)}

    load_balancer = LoadBalancer(user_loc_to_selectors)

    latency_table = {
        UserLocId(i + 1): {
            DataCenterId(j + 1): scenario.base.network_latency_matrix[i][j]
            for j in range(scenario.base.data_center_count)
        }
        for i in range(scenario.base.user_location_count)
    }

    request_generator = RequestGenerator(
        env,
        user_loc_to_iat_gen,
        dc_to_st_gen,
        dc_to_servers,
        load_balancer,
        latency_table,
    )

    env.run(until=600)
    response_times = [
        request.response_ts - request.arrival_ts
        for request in request_generator.generated_requests
        if request.response_ts is not None and request.arrival_ts > 60
    ]
    print(np.mean(response_times))
