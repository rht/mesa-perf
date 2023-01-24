# cython: infer_types=True, language_level=3
# cython: nonecheck=False
# See https://cython.readthedocs.io/en/latest/src/userguide/source_files_and_compilation.html#compiler-directives

cimport cython
import numpy as np


cdef class _Grid:
    cdef long height, width, num_cells
    cdef bint torus
    cdef long[:, :] _grid
    cdef dict _agent_map

    def __init__(self, long width, long height, bint torus):
        self.height = height
        self.width = width
        self.torus = torus
        self.num_cells = height * width

        self._grid = np.full((self.width, self.height), self.default_val(), dtype=long)

        self._agent_map = {}

    cpdef long default_val(self):
        return -1

    cpdef is_cell_empty(self, pos):
        cdef long x, y

        x, y = pos[0], pos[1]
        return self._grid[x, y] == self.default_val()

    cpdef place_agent(self, agent, pos):
        cdef long x, y, agent_id

        if self.is_cell_empty(pos):
            x, y = pos[0], pos[1]
            agent_id = agent.unique_id
            self._grid[x, y] = agent_id
            self._agent_map[agent_id] = agent
            agent.pos = pos
        else:
            raise Exception("Cell not empty")

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef object[:] get_cell_mview_contents(self, long[:, :] tuples_mview):
        cdef long default_val
        cdef int count
        cdef object[:] agent_mview
        
        length = len(tuples_mview)
        agent_mview = np.ndarray(length, object)
        count = 0
        default_val = self.default_val()
        for i in range(length):
            id_agent = self._grid[tuples_mview[i, 0], tuples_mview[i, 1]]
            if id_agent == default_val:
                continue
            agent_mview[i] = self._agent_map[id_agent]
            count += 1
        return agent_mview[:count]
 
    @cython.wraparound(False)
    @cython.boundscheck(False)   
    cpdef long[:, :] convert_tuples_to_mview(self, object cell_list):
        cdef long x, y
        cdef long[:, :] tuples_mview

        length = len(cell_list)
        tuples_mview = np.ndarray((length, 2), long)

        for i in range(length):
            pos = cell_list[i]
            x, y = pos[0], pos[1]
            tuples_mview[i, 0], tuples_mview[i, 1] = x, y

        return tuples_mview
    
    @cython.wraparound(False)
    @cython.boundscheck(False) 
    cpdef list convert_agent_mview_to_list(self, object[:] agent_mview):
        
        length = len(agent_mview)
        agent_list = [0] * length
        
        for i in range(length):
            agent_list[i] = agent_mview[i]
        
        return agent_list
    
    cpdef get_cell_list_contents(self, object cell_list):
    
        tuples_mview = self.convert_tuples_to_mview(cell_list)
        agent_mview = self.get_cell_mview_contents(tuples_mview)
        return self.convert_agent_mview_to_list(agent_mview)

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef long[:, :] get_neighborhood_mview(self, object pos, bint moore, int radius, bint include_center):

        cdef long neighborhood_c[(radius*2+1)**2][2]
        cdef long [:, :] neighborhood = neighborhood_c
        #cdef long[:, :] neighborhood
        cdef long nx, ny
        cdef int x_radius, y_radius, dx, dy, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count
     
        #neighborhood = np.empty(((radius*2+1)**2, 2), long)
        x, y = pos[0], pos[1]
        count = 0
        if self.torus:

            x_max_radius, y_max_radius = self.width // 2, self.height // 2
            x_radius, y_radius = min(radius, x_max_radius), min(radius, y_max_radius)

            xdim_even, ydim_even = (self.width + 1) % 2, (self.height + 1) % 2
            kx = 1 if x_radius == x_max_radius and xdim_even else 0
            ky = 1 if y_radius == y_max_radius and ydim_even else 0

            for dx in range(-x_radius, x_radius + 1 - kx):
                for dy in range(-y_radius, y_radius + 1 - ky):

                    if not moore and abs(dx) + abs(dy) > radius:
                        continue

                    nx = (x + dx) % self.width
                    ny = (y + dy) % self.height

                    if nx == x and ny == y and not include_center:
                        continue

                    neighborhood[count, 0] = nx
                    neighborhood[count, 1] = ny
                    count += 1
        else:
            min_x_range = max(0, x - radius)
            max_x_range = min(self.width, x + radius + 1)
            min_y_range = max(0, y - radius)
            max_y_range = min(self.height, y + radius + 1)

            for nx in range(min_x_range, max_x_range):
                for ny in range(min_y_range, max_y_range):

                    if not moore and abs(nx - x) + abs(ny - y) > radius:
                        continue

                    if nx == x and ny == y and not include_center:
                        continue

                    neighborhood[count, 0] = nx
                    neighborhood[count, 1] = ny
                    count += 1
        
        return neighborhood[:count]
    
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center):
        
        cdef list neighborhood_list
        neighborhood_mview = self.get_neighborhood_mview(pos, moore, radius, include_center)

        count = len(neighborhood_mview)
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood_mview[i, 0], neighborhood_mview[i, 1])
        return neighborhood_list

cdef class _Grid_NoMap:
    cdef long height, width, num_cells
    cdef bint torus
    cdef object[:, :] _grid
    cdef dict _agent_map

    def __init__(self, long width, long height, bint torus):
        self.height = height
        self.width = width
        self.torus = torus
        self.num_cells = height * width

        self._grid = np.full((self.width, self.height), self.default_val(), dtype=object)

    cpdef default_val(self):
        return None

    cpdef is_cell_empty(self, pos):
        cdef long x, y

        x, y = pos[0], pos[1]
        return self._grid[x, y] == self.default_val()

    cpdef place_agent(self, agent, pos):
        cdef long x, y

        if self.is_cell_empty(pos):
            x, y = pos[0], pos[1]
            agent_id = agent.unique_id
            self._grid[x, y] = agent
            agent.pos = pos
        else:
            raise Exception("Cell not empty")

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef object[:] get_cell_mview_contents(self, long[:, :] tuples_mview):
        cdef int count
        cdef object[:] agent_mview
        
        length = len(tuples_mview)
        agent_mview = np.ndarray(length, object)
        count = 0
        default_val = self.default_val()
        for i in range(length):
            agent = self._grid[tuples_mview[i, 0], tuples_mview[i, 1]]
            if agent == default_val:
                continue
            agent_mview[i] = agent
            count += 1
        return agent_mview[:count]
 
    @cython.wraparound(False)
    @cython.boundscheck(False)   
    cpdef long[:, :] convert_tuples_to_mview(self, object cell_list):
        cdef long x, y
        cdef long[:, :] tuples_mview

        length = len(cell_list)
        tuples_mview = np.ndarray((length, 2), long)

        for i in range(length):
            pos = cell_list[i]
            x, y = pos[0], pos[1]
            tuples_mview[i, 0], tuples_mview[i, 1] = x, y

        return tuples_mview
    
    @cython.wraparound(False)
    @cython.boundscheck(False) 
    cpdef list convert_agent_mview_to_list(self, object[:] agent_mview):
        
        length = len(agent_mview)
        agent_list = [0] * length
        
        for i in range(length):
            agent_list[i] = agent_mview[i]
        
        return agent_list
    
    cpdef get_cell_list_contents(self, object cell_list):
    
        tuples_mview = self.convert_tuples_to_mview(cell_list)
        agent_mview = self.get_cell_mview_contents(tuples_mview)
        return self.convert_agent_mview_to_list(agent_mview)

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef long[:, :] get_neighborhood_mview(self, object pos, bint moore, int radius, bint include_center):

        cdef long[:, :] neighborhood
        cdef long nx, ny
        cdef int x_radius, y_radius, dx, dy, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count

        neighborhood = np.empty(((radius*2+1)**2, 2), int)
        x, y = pos[0], pos[1]
        count = 0
        if self.torus:

            x_max_radius, y_max_radius = self.width // 2, self.height // 2
            x_radius, y_radius = min(radius, x_max_radius), min(radius, y_max_radius)

            xdim_even, ydim_even = (self.width + 1) % 2, (self.height + 1) % 2
            kx = 1 if x_radius == x_max_radius and xdim_even else 0
            ky = 1 if y_radius == y_max_radius and ydim_even else 0

            for dx in range(-x_radius, x_radius + 1 - kx):
                for dy in range(-y_radius, y_radius + 1 - ky):

                    if not moore and abs(dx) + abs(dy) > radius:
                        continue

                    nx = (x + dx) % self.width
                    ny = (y + dy) % self.height

                    if nx == x and ny == y and not include_center:
                        continue

                    neighborhood[count, 0] = nx
                    neighborhood[count, 1] = ny
                    count += 1
        else:
            min_x_range = max(0, x - radius)
            max_x_range = min(self.width, x + radius + 1)
            min_y_range = max(0, y - radius)
            max_y_range = min(self.height, y + radius + 1)

            for nx in range(min_x_range, max_x_range):
                for ny in range(min_y_range, max_y_range):

                    if not moore and abs(nx - x) + abs(ny - y) > radius:
                        continue

                    if nx == x and ny == y and not include_center:
                        continue

                    neighborhood[count, 0] = nx
                    neighborhood[count, 1] = ny
                    count += 1
        
        return neighborhood[:count]
    
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center):
    
        cdef list neighborhood_list
        neighborhood_mview = self.get_neighborhood_mview(pos, moore, radius, include_center)
        
        count = len(neighborhood_mview)
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood_mview[i, 0], neighborhood_mview[i, 1])
        return neighborhood_list
        
