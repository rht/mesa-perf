# cython: infer_types=True, language_level=3
# distutils: language = c++
cimport cython
from libcpp.map cimport map as cpp_map
from cython.operator import dereference, postincrement
from cpython.ref cimport PyObject
import numpy as np
# from numpy.random import default_rng

# For shuffle
from libc.stdlib cimport rand
from libc.math cimport floor
from libcpp.vector cimport vector


ctypedef PyObject* PyObjectPtr

# https://stackoverflow.com/questions/16138090/correct-way-to-generate-random-numbers-in-cython
cdef extern from "stdlib.h":
    int RAND_MAX

# https://gist.github.com/JenkinsDev/1e4bff898c72ec55df6f
@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef void fisher_yates_shuffle(long[:] the_list) nogil:
    cdef int amnt_to_shuffle
    with gil:
        amnt_to_shuffle = len(the_list)
    cdef int i
    cdef long a, b
    cdef float rnd
    while amnt_to_shuffle > 1:
        rnd = rand() / RAND_MAX
        i = int(floor(rnd * amnt_to_shuffle))
        amnt_to_shuffle -= 1
        a = the_list[i]
        b = the_list[amnt_to_shuffle]
        the_list[i] = b
        the_list[amnt_to_shuffle] = a


@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef void fisher_yates_shuffle_vector(list input_list) nogil:
    cdef vector[long] the_list
    cdef int amnt_to_shuffle
    with gil:
        the_list = input_list
        amnt_to_shuffle = len(the_list)
    cdef int i
    cdef long a, b
    cdef float rnd
    while amnt_to_shuffle > 1:
        rnd = rand() / RAND_MAX
        i = int(floor(rnd * amnt_to_shuffle))
        amnt_to_shuffle -= 1
        a = the_list[i]
        b = the_list[amnt_to_shuffle]
        the_list[i] = b
        the_list[amnt_to_shuffle] = a


cdef class SchedulerPythonDict:
    cdef object model
    cdef dict _agents
    cdef bint shuffle
    cdef bint fisher_yates
    # cdef object rng
    def __init__(self, object model, bint shuffle, bint fisher_yates):
        self.model = model
        self._agents = {}
        self.shuffle = shuffle
        # self.rng = default_rng(model.random.randint(0, 1000_000))
        self.fisher_yates = fisher_yates

    cpdef add(self, object agent):
        self._agents[agent.unique_id] = agent

    def step(self):
        agent_keys = list(self._agents.keys())
        if self.shuffle:
            # for agent_key in agent_keys[np.random.permutation(len(agent_keys))]:
            # self.model.random.shuffle(agent_keys)
            if self.fisher_yates:
                fisher_yates_shuffle_vector(agent_keys)
            else:
                np.random.shuffle(agent_keys)
            # self.rng.shuffle(agent_keys)
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
    cdef bint fisher_yates
    def __init__(self, object model, bint shuffle, bint fisher_yates):
        self.model = model
        self._agents = {}
        self.shuffle = shuffle
        self.fisher_yates = fisher_yates

    cpdef add(self, Agent agent):
        self._agents[agent.unique_id] = agent

    cpdef step(self):
        cdef Agent agent
        cdef list agent_keys
        cdef long agent_key
        agent_keys = list(self._agents.keys())
        if self.shuffle:
            # self.model.random.shuffle(agent_keys)
            if self.fisher_yates:
                fisher_yates_shuffle_vector(agent_keys)
            else:
                np.random.shuffle(agent_keys)
        for agent_key in agent_keys:
            agent = self._agents[agent_key]
            agent.step()


cdef class SchedulerMap:
    # https://stackoverflow.com/questions/35695877/cython-cpp-dict-like-map-performance
    # https://stackoverflow.com/questions/51686143/cython-iterate-through-map
    cdef object model
    cdef cpp_map[long, PyObjectPtr] _agents
    cdef bint shuffle
    cdef dict _agents_dict
    cdef bint fisher_yates
    def __init__(self, object model, bint shuffle, bint fisher_yates):
        self.model = model
        self.shuffle = shuffle
        self._agents_dict = {}
        self.fisher_yates = fisher_yates

    cpdef add(self, agent):
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
            if self.fisher_yates:
                fisher_yates_shuffle(agent_keys)
            else:
                np.random.shuffle(agent_keys)

        cdef long agent_key
        cdef Agent agent
        for i in range(count):
            agent_key = agent_keys[i]
            agent = <Agent>self._agents[agent_key]
            agent.step()


# cdef class SchedulerMapDictCast:
#     # https://stackoverflow.com/questions/51686143/cython-iterate-through-map
#     cdef object model
#     cdef dict _agents
#     cdef bint shuffle
#     def __init__(self, object model, bint shuffle):
#         self.model = model
#         self.shuffle = shuffle
#         self._agents = {}
# 
#     cpdef add(self, agent):
#         self._agents[agent.unique_id] = agent
# 
#     cpdef step(self):
#         # python dict to map
#         cdef cpp_map[long, PyObjectPtr] map_in = self._agents
#         cdef cpp_map[long, PyObjectPtr].iterator it = map_in.begin()
#         # cdef long[:] agent_keys
#         # agent_keys = np.zeros(map_in.size(), dtype=int)
#         cdef long agent_keys[200]
#         cdef int count
#         count = 0
#         while it != map_in.end():
#             agent_keys[count] = dereference(it).first
#             postincrement(it)
#             count += 1
# 
#         cdef long agent_key
#         cdef Agent agent
#         for i in range(count):
#             agent_key = agent_keys[i]
#             agent = self._agents[agent_key]
#             agent.step()
