# cython: infer_types=True, language_level=3
cimport cython
# from libcpp.map cimport map as cpp_map

cdef class SchedulerPythonDict:
    cdef object model
    cdef dict _agents
    def __init__(self, object model):
        self.model = model
        self._agents = {}

    cpdef add(self, object agent):
        self._agents[agent.unique_id] = agent

    cpdef step(self):
        for agent in self._agents.values():
            agent.step()


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
    def __init__(self, object model):
        self.model = model
        self._agents = {}

    cpdef add(self, Agent agent):
        self._agents[agent.unique_id] = agent

    cpdef step(self):
        cdef Agent agent
        for agent in self._agents.values():
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
