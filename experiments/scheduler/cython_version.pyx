# cython: infer_types=True, language_level=3
cimport cython
from libcpp.map cimport map as cpp_map

cdef class SchedulerPythonDict:
    cdef object model
    cdef dict _agents
    def __init__(self, object model):
        self.model = model
        self._agents = {}

    cpdef add(self, agent):
        self._agents[agent.unique_id] = agent

    cpdef step(self):
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
