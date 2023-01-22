# cython: infer_types=True, language_level=3
# cython: nonecheck=False
# cython: cdivision=True
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
    cpdef list get_cell_list_contents(self, object cell_list):
        cdef long default_val, x, y
        cdef int count
        cdef long[:] ids_mview
        cdef list agent_list

        length = len(cell_list)
        ids_mview = np.ndarray(length, long)

        count = 0
        default_val = self.default_val()
        for i in range(length):
            pos = cell_list[i]
            x, y = pos[0], pos[1]
            id_agent = self._grid[x, y]
            if id_agent == default_val:
                continue
            ids_mview[count] = id_agent
            count += 1

        agent_list = [0] * count
        for i in range(count):
            agent_list[i] = self._agent_map[ids_mview[i]]
        return agent_list

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center):
        cdef long nx, ny
        cdef int x_radius, y_radius, dx, dy, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count
        cdef long[:, :] neighborhood
        cdef list neighborhood_list

        neighborhood = np.empty(((radius*2+1)**2, 2), int)
        x, y = pos
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

        neighborhood_list = [[0, 0]] * count
        for i in range(count):
            # We do this instead of
            # "neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])"
            # because tuple creation is expensive
            neighborhood_list[i][0] = neighborhood[i, 0]
            neighborhood_list[i][1] = neighborhood[i, 1]
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
    cpdef list get_cell_list_contents(self, object cell_list):
        cdef long x, y
        cdef int count
        cdef long[:] ids_mview
        cdef list agent_list

        length = len(cell_list)
        agent_mview = np.ndarray(length, object)

        count = 0
        default_val = self.default_val()
        for i in range(length):
            pos = cell_list[i]
            x, y = pos[0], pos[1]
            agent = self._grid[x, y]
            if agent == default_val:
                continue
            agent_mview[count] = agent
            count += 1

        agent_list = [0] * count
        for i in range(count):
            agent_list[i] = agent_mview[i]
        return agent_list

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef list get_neighborhood(self, object pos, bint moore, int radius, bint include_center):

        cdef long[:, :] neighborhood
        cdef list neighborhood_list
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

        neighborhood_list = [[0, 0]] * count
        for i in range(count):
            # We do this instead of
            # "neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])"
            # because tuple creation is expensive
            neighborhood_list[i][0] = neighborhood[i, 0]
            neighborhood_list[i][1] = neighborhood[i, 1]
        return neighborhood_list
