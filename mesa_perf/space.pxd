cdef class _Grid:
    cdef long height, width, num_cells, num_empties
    cdef bint torus
    cdef long[:, :] _ids_grid
    # TODO make private
    cdef public object[:, :] _agents_grid
    cdef dict _neighborhood_cache_cy
    cdef dict _neighborhood_cache_py
    cpdef long _default_val_ids(self)
    cpdef default_val(self)
    cpdef bint is_cell_empty(self, pos)
    cpdef place_agent(self, agent, pos)
    cpdef remove_agent(self, agent)
    cpdef object[:] get_cell_mview_contents(self, long[:, :] tuples_mview)
    cpdef long[:, :] convert_tuples_to_mview(self, object cell_list)
    cpdef list convert_agent_mview_to_list(self, object[:] agent_mview)
    cpdef get_cell_list_contents(self, object cell_list)
    cpdef long[:, :] compute_neighborhood(self, object pos, bint moore, int radius, bint include_center)
    cpdef long[:, :] get_neighborhood_mview(self, object pos, bint moore, int radius, bint include_center)
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center)
    cpdef object[:] get_neighbors_mview(self, object pos, bint moore, int radius, bint include_center)
    cpdef list get_neighbors(self, object pos, bint moore, int radius, bint include_center)
    cpdef move_to_empty(self, agent)
