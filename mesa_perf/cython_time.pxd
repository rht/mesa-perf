from cpython.ref cimport PyObject
from libcpp.map cimport map as cpp_map


ctypedef PyObject* PyObjectPtr

cdef class Agent:
    cdef readonly long unique_id
    cdef readonly object model
    cpdef step(self)


cdef class SchedulerMap:
    cdef object model
    cdef cpp_map[long, PyObjectPtr] _agents
    cdef bint shuffle
    cdef dict _agents_dict
    cpdef add(self, Agent agent)
    cpdef step(self)
    cpdef int get_agent_count(self)


cdef class SchedulerPythonDict:
    cdef object model
    cdef dict _agents
    cdef bint shuffle
    # cdef object rng
    cpdef add(self, object agent)
    cpdef step(self)
    cpdef int get_agent_count(self)
