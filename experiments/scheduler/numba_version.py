import numba as nb
from numba.experimental import jitclass
from numba.core import types
from numba.typed import Dict

@nb.njit(cache=True)
def jit_step(d):
    for agent in d.values():
        agent.step()

@jitclass([])
class Model:
    def __init__(self):
        pass

spec = [
    ("unique_id", types.int64),
    ("model", Model.class_type.instance_type),
    ("name", types.int64),
]

@jitclass(spec)
class Agent:
    def __init__(self, unique_id, model):
        self.unique_id = unique_id
        self.model = model

    def step(self):
        pass


class Scheduler:
    def __init__(self, model):
        self.model = model
        self._agents = Dict.empty(
            key_type=types.int64,
            value_type=Agent.class_type.instance_type,
        )

    def add(self, agent):
        self._agents[agent.unique_id] = agent

    def step(self):
        jit_step(self._agents)
