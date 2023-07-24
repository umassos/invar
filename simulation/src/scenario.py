import yaml
from pydantic import BaseModel, StrictInt


class BaseScenario(BaseModel, frozen=True):
    user_location_count: StrictInt
    arrival_rate_vector: list[float]
    data_center_count: StrictInt
    max_capacity_vector: list[StrictInt]
    service_rate_vector: list[float]
    server_cost_vector: list[float]
    network_latency_matrix: list[list[float]]


class SimulationScenario(BaseScenario, frozen=True):
    base: BaseScenario
    calculated_performance: float
    allocation_vector: list[StrictInt]
    forwarding_probability_matrix: list[list[float]]


def load_simulation_scenario(filename: str) -> SimulationScenario:
    with open(filename) as fin:
        data = yaml.load(fin, Loader=yaml.CLoader)
    return SimulationScenario(**data)
