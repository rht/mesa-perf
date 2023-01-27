# distutils: language = c++
# cython: infer_types=True, language_level=3
# cython: nonecheck=False
# See https://cython.readthedocs.io/en/latest/src/userguide/source_files_and_compilation.html#compiler-directives

cimport cython
import numpy as np
from cython cimport view
import random


cdef class _Grid:
    def __init__(self, long width, long height, bint torus):
        self.height = height
        self.width = width
        self.torus = torus
        self.num_cells = height * width
        self.num_empties = self.num_cells

        self._ids_grid = np.full((self.width, self.height), self._default_val_ids(), dtype=long)
        self._agents_grid = np.full((self.width, self.height), self.default_val(), dtype=object)
        
        # Neighborhood caches
        self._neighborhood_cache_py = {}
        self._neighborhood_cache_cy = {}

    cpdef long _default_val_ids(self):
        return -1
    
    cpdef default_val(self):
        return None
    
    # TODO: we need fused types for pos arg for fast execution
    cpdef bint is_cell_empty(self, pos):
        cdef long x, y

        x, y = pos[0], pos[1]
        return self._ids_grid[x, y] == self._default_val_ids()

    cpdef place_agent(self, agent, pos):
        cdef long x, y, agent_id

        if self.is_cell_empty(pos):
            x, y = pos[0], pos[1]
            agent_id = agent.unique_id
            self._ids_grid[x, y] = agent_id
            self._agents_grid[x, y] = agent
            agent.pos = pos
            self.num_empties -= 1
        else:
            raise Exception("Cell not empty")
            
    cpdef remove_agent(self, agent):
        cdef long x, y, agent_id
        if (pos := agent.pos) is None:
            return
        x, y = pos
        self._ids_grid[x][y] = self._default_val_ids()
        self._agents_grid[x][y] = self.default_val()
        self.num_empties += 1
        agent.pos = None

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef object[:] get_cell_mview_contents(self, long[:, :] tuples_mview):
        cdef long default_val
        cdef int count
        cdef object[:] agent_mview
        cdef long x, y

        length = len(tuples_mview)
        agent_mview = np.ndarray(length, object)
        count = 0
        default_val = self._default_val_ids()
        for i in range(length):
            x, y = tuples_mview[i, 0], tuples_mview[i, 1]
            id_agent = self._ids_grid[x, y]
            if id_agent == default_val:
                continue
            agent_mview[count] = self._agents_grid[x, y]
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
    cpdef long[:, :] compute_neighborhood(self, object pos, bint moore, int radius, bint include_center):
        
        cdef long[:, :] neighborhood
        cdef long nx, ny
        cdef int x_radius, y_radius, dx, dy, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count

        neighborhood = np.empty(((radius*2+1)**2, 2), long)
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
        
    cpdef long[:, :] get_neighborhood_mview(self, object pos, bint moore, int radius, bint include_center):
    
        cache_key = (pos, moore, include_center, radius)
        cached_neighborhood = self._neighborhood_cache_cy.get(cache_key, None)
        
        if cached_neighborhood is not None:
            return cached_neighborhood
        
        neighborhood = self.compute_neighborhood(pos, moore, radius, include_center)
        
        self._neighborhood_cache_cy[cache_key] = neighborhood

        return neighborhood
        
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center):
    
        cache_key = (pos, moore, include_center, radius)
        cached_neighborhood = self._neighborhood_cache_py.get(cache_key, None)
        
        if cached_neighborhood is not None:
            return cached_neighborhood
        
        cdef list neighborhood_list
        
        neighborhood = self.compute_neighborhood(pos, moore, radius, include_center)
        
        count = len(neighborhood)
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])
        
        self._neighborhood_cache_py[cache_key] = neighborhood_list

        return neighborhood_list
    
    cpdef object[:] get_neighbors_mview(self, object pos, bint moore, int radius, bint include_center):
        
        neighborhood_mview = self.get_neighborhood_mview(pos, moore, radius, include_center)
        return self.get_cell_mview_contents(neighborhood_mview)
    
    cpdef list get_neighbors(self, object pos, bint moore, int radius, bint include_center):
    
        neighbors_mview = self.get_neighbors_mview(pos, moore, radius, include_center)
        return self.convert_agent_mview_to_list(neighbors_mview)

    cpdef move_to_empty(self, agent):
        while True:
            new_pos = (random.randrange(self.width), random.randrange(self.height))
            if self.is_cell_empty(new_pos):
                break
        self.remove_agent(agent)
        self.place_agent(agent, new_pos)


cdef class _Grid_NoMap:
    cdef long height, width, num_cells
    cdef bint torus
    cdef object[:, :] _grid
    cdef dict _neighborhood_cache_cy
    cdef dict _neighborhood_cache_py

    def __init__(self, long width, long height, bint torus):
        self.height = height
        self.width = width
        self.torus = torus
        self.num_cells = height * width

        self._grid = np.full((self.width, self.height), self.default_val(), dtype=object)
        
        # Neighborhood caches
        self._neighborhood_cache_py = {}
        self._neighborhood_cache_cy = {}


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
    cpdef long[:, :] compute_neighborhood(self, object pos, bint moore, int radius, bint include_center):
        
        cdef long[:, :] neighborhood
        cdef long nx, ny
        cdef int x_radius, y_radius, dx, dy, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count

        neighborhood = np.empty(((radius*2+1)**2, 2), long)
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
        
    cpdef long[:, :] get_neighborhood_mview(self, object pos, bint moore, int radius, bint include_center):
    
        cache_key = (pos, moore, include_center, radius)
        cached_neighborhood = self._neighborhood_cache_cy.get(cache_key, None)
        
        if cached_neighborhood is not None:
            return cached_neighborhood
        
        neighborhood = self.compute_neighborhood(pos, moore, radius, include_center)
        
        self._neighborhood_cache_cy[cache_key] = neighborhood

        return neighborhood
        
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center):
    
        cache_key = (pos, moore, include_center, radius)
        cached_neighborhood = self._neighborhood_cache_py.get(cache_key, None)
        
        if cached_neighborhood is not None:
            return cached_neighborhood
        
        cdef list neighborhood_list
        
        neighborhood = self.compute_neighborhood(pos, moore, radius, include_center)
        
        count = len(neighborhood)
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])
        
        self._neighborhood_cache_py[cache_key] = neighborhood_list

        return neighborhood_list
        
    cpdef object[:] get_neighbors_mview(self, object pos, bint moore, int radius, bint include_center):
        
        neighborhood_mview = self.get_neighborhood_mview(pos, moore, radius, include_center)
        return self.get_cell_mview_contents(neighborhood_mview)
    
    cpdef list get_neighbors(self, object pos, bint moore, int radius, bint include_center):
    
        neighbors_mview = self.get_neighbors_mview(pos, moore, radius, include_center)
        return self.convert_agent_mview_to_list(neighbors_mview)
