# cython: infer_types=True, language_level=3
# distutils: language = c++
cimport cython
from libcpp.map cimport map as cpp_map
from cython.operator import dereference, postincrement
import numpy as np
# from numpy.random import default_rng

# For shuffle
from libc.stdlib cimport rand
from libc.math cimport floor
from libcpp.vector cimport vector


cdef class Agent:
    def __init__(self, unique_id, model):
        self.unique_id = unique_id
        self.model = model

    cpdef step(self):
        pass


cdef class SchedulerMap:
    # https://stackoverflow.com/questions/35695877/cython-cpp-dict-like-map-performance
    # https://stackoverflow.com/questions/51686143/cython-iterate-through-map
    def __init__(self, object model, bint shuffle):
        self.model = model
        self.shuffle = shuffle
        self._agents_dict = {}

    cpdef add(self, Agent agent):
        self._agents[agent.unique_id] = <PyObjectPtr>agent
        # The agent must be put in the dict, otherwise it gets gc-ed
        self._agents_dict[agent.unique_id] = agent

    cpdef step(self):
        cdef cpp_map[long, PyObjectPtr].iterator it = self._agents.begin()
        cdef int length
        #length = self._agents.size()
        cdef long agent_keys[200]
        #cdef long[:] agent_keys
        #agent_keys = np.empty(self._agents.size(), dtype=int)
        cdef int count
        count = 0
        while it != self._agents.end():
            agent_keys[count] = dereference(it).first
            postincrement(it)
            count += 1

        if self.shuffle:
            np.random.shuffle(agent_keys)

        cdef long agent_key
        cdef Agent agent
        for i in range(count):
            agent_key = agent_keys[i]
            agent = <Agent>self._agents[agent_key]
            agent.step()

    cpdef int get_agent_count(self):
        return self._agents.size()


cdef class SchedulerPythonDict:
    def __init__(self, object model, bint shuffle):
        self.model = model
        self._agents = {}
        self.shuffle = shuffle
        # self.rng = default_rng(model.random.randint(0, 1000_000))

    cpdef add(self, object agent):
        self._agents[agent.unique_id] = agent

    cpdef step(self):
        agent_keys = list(self._agents.keys())
        if self.shuffle:
            # for agent_key in agent_keys[np.random.permutation(len(agent_keys))]:
            # self.model.random.shuffle(agent_keys)
            np.random.shuffle(agent_keys)
            # self.rng.shuffle(agent_keys)
        for agent_key in agent_keys:
            self._agents[agent_key].step()

    cpdef int get_agent_count(self):
        return len(self._agents)
