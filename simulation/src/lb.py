from predef import DataCenterId, UserLocId
from rng import ChoiceRNG


class LoadBalancer:
    def __init__(self, user_loc_to_selectors: dict[UserLocId, ChoiceRNG]):
        self.user_loc_to_selectors = user_loc_to_selectors

    def schedule(self, user_loc_id: UserLocId) -> DataCenterId:
        return self.user_loc_to_selectors[user_loc_id].sample()
