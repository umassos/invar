from simpy import Environment

from scenario import load_scenario

if __name__ == "__main__":
    scenario = load_scenario("")
    env = Environment()
    datacenters = {datacenter_id: 1 for datacenter_id in range(1, scenario.base.data_center_count)}
