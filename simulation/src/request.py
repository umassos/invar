import itertools
import operator

from simpy import Environment
from simpy.resources.resource import PriorityResource

from lb import LoadBalancer
from predef import *
from rng import RNG


class Request:
    def __init__(
        self,
        request_id: RequestId,
        user_location_id: UserLocId,
        arrival_ts: float,
        data_center_id: DataCenterId,
        latency: float,
        servers: PriorityResource,
        service_time: float,
        env: Environment,
    ):
        self.request_id = request_id
        self.user_location_id = user_location_id
        self.arrival_ts = arrival_ts
        self.data_center_id = data_center_id
        self.latency = latency
        self.servers = servers
        self.service_time = service_time
        self.env = env

        self.enqueue_ts: float | None = None
        self.start_ts: float | None = None
        self.completion_ts: float | None = None
        self.response_ts: float | None = None

        self.process = env.process(self.run())

    def run(self):
        yield self.env.timeout(self.latency / 2)
        self.enqueue_ts = self.env.now
        with self.servers.request() as req:
            yield req
            self.start_ts = self.env.now
            yield self.env.timeout(self.service_time)
            self.completion_ts = self.env.now
        yield self.env.timeout(self.latency / 2)
        self.response_ts = self.env.now


class RequestGenerator:
    def __init__(
        self,
        env: Environment,
        user_loc_to_iat_gen: dict[UserLocId, RNG],
        dc_to_st_gen: dict[DataCenterId, RNG],
        dc_to_servers: dict[DataCenterId, PriorityResource],
        load_balancer: LoadBalancer,
        latency_matrix: dict[UserLocId, dict[DataCenterId, float]],
    ):
        self.user_loc_to_iat_gen = user_loc_to_iat_gen
        self.dc_to_st_gen = dc_to_st_gen
        self.dc_to_servers = dc_to_servers
        self.load_balancer = load_balancer
        self.latency_matrix = latency_matrix
        self.env = env
        self.request_count = itertools.count()
        self.generated_requests = []

        self.process = env.process(self.run())

    def run(self):
        user_loc_to_next_arrival_ts = {
            user_loc_id: rng.sample() for (user_loc_id, rng) in self.user_loc_to_iat_gen.items()
        }

        while True:
            user_loc_id, arrival_ts = min(user_loc_to_next_arrival_ts.items(), key=operator.itemgetter(1))
            yield self.env.timeout(arrival_ts - self.env.now)
            data_center_id = self.load_balancer.schedule(user_loc_id)
            service_time = self.dc_to_st_gen[data_center_id].sample()
            request = Request(
                request_id=next(self.request_count),
                user_location_id=user_loc_id,
                arrival_ts=arrival_ts,
                data_center_id=data_center_id,
                latency=self.latency_matrix[user_loc_id][data_center_id],
                servers=self.dc_to_servers[data_center_id],
                service_time=service_time,
                env=self.env,
            )
            self.generated_requests.append(request)
            user_loc_to_next_arrival_ts[user_loc_id] = self.env.now + self.user_loc_to_iat_gen[user_loc_id].sample()
