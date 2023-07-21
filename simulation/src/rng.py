from abc import ABC, abstractmethod

from numpy.random import Generator, default_rng


class RNG(ABC):
    @abstractmethod
    def sample(self):
        raise NotImplementedError


class ExponentialRNG(RNG):
    def __init__(self, rate: float, generator: None):
        self.scale = 1 / rate
        self._generator = generator if generator else default_rng()

    def sample(self):
        return self._generator.exponential(scale=self.scale)
