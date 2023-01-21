# cython: infer_types=True, language_level=3
cimport cython
# from libcpp.map cimport map as cpp_map
import numpy as np

cdef class SchedulerPythonDict:
    cdef object model
    cdef dict _agents
    cdef bint shuffle
    def __init__(self, object model, bint shuffle):
        self.model = model
        self._agents = {}
        self.shuffle = shuffle

    cpdef add(self, object agent):
        self._agents[agent.unique_id] = agent

    def step(self):
        agent_keys = list(self._agents.keys())
        if self.shuffle:
            #for agent_key in agent_keys[np.random.permutation(len(agent_keys))]:
            self.model.random.shuffle(agent_keys)
        for agent_key in agent_keys:
            self._agents[agent_key].step()


cdef class Agent:
    cdef readonly long unique_id
    cdef readonly object model
    def __init__(self, unique_id, model):
        self.unique_id = unique_id
        self.model = model

    cpdef step(self):
        pass


cdef class SchedulerDictCythonizedAgent:
    cdef object model
    cdef dict _agents
    cdef bint shuffle
    def __init__(self, object model, bint shuffle):
        self.model = model
        self._agents = {}
        self.shuffle = shuffle

    cpdef add(self, Agent agent):
        self._agents[agent.unique_id] = agent

    cpdef step(self):
        cdef Agent agent
        cdef list agent_keys
        cdef long agent_key
        agent_keys = list(self._agents.keys())
        if self.shuffle:
            self.model.random.shuffle(agent_keys)
        for agent_key in agent_keys:
            agent = self._agents[agent_key]
            agent.step()


# TODO
# cdef class SchedulerMap:
#     cdef object model
#     cdef dict _agents
#     def __init__(self, object model):
#         self.model = model
#         self._agents = {}
# 
#     cpdef add(self, agent):
#         self._agents[agent.unique_id] = agent
# 
#     cpdef step(self):
#         for agent in self._agents.values():
#             agent.step()
