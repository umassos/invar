from abc import ABC, abstractmethod

from numpy.random import Generator, default_rng


class RNG(ABC):
    @abstractmethod
    def sample(self):
        raise NotImplementedError


class ExponentialRNG(RNG):
    def __init__(self, rate: float, generator: Generator | None = None):
        self.scale = 1 / rate
        self._generator = generator if generator else default_rng()

    def sample(self):
        return self._generator.exponential(scale=self.scale)


class ChoiceRNG(RNG):
    def __init__(self, choices: list, probabilities: list[float], generator: Generator | None):
        self.choices = choices
        self.probabilities = probabilities
        self._generator = generator if generator else default_rng()

    def sample(self):
        return self._generator.choice(self.choices, p=self.probabilities)
