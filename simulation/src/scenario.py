import yaml
from pydantic import BaseModel, StrictInt


class BaseScenario(BaseModel, frozen=True):
    user_location_count: StrictInt
    arrival_rate_vector: list[float]
    data_center_count: StrictInt
    max_capacity_vector: list[float]
    service_rate_vector: list[float]
    server_cost_vector: list[float]
    network_latency_matrix: list[list[float]]


class Scenario(BaseScenario, frozen=True):
    base: BaseScenario
    performance_target: float
    budget: float


def load_scenario(filename: str) -> Scenario:
    with open(filename) as fin:
        data = yaml.load(fin, Loader=yaml.CLoader)
    return Scenario(**data)
