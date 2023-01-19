# cython: infer_types=True, language_level=3
import itertools

cimport cython
from cpython cimport array
import array
import numpy as np

cdef class Grid:
    cdef int height
    cdef int width
    cdef bint torus
    cdef int num_cells
    cdef long[:, :] _grid
    cdef dict agent_map

    def __init__(self, width: int, height: int) -> None:
        self.height = height
        self.width = width
        #self.torus = torus
        self.num_cells = height * width

        # self._grid = np.empty((self.width, self.height), self.default_val())
        self._grid = np.full((self.width, self.height), self.default_val(), dtype=long)

        self.agent_map = {}

    cpdef long default_val(self):
        return -1

    cpdef is_cell_empty(self, pos):
        cdef long x, y
        x, y = pos
        return self._grid[x, y] == self.default_val()

    cpdef place_agent(self, agent, pos):
        cdef long x, y
        cdef int agent_id
        if self.is_cell_empty(pos):
            x, y = pos
            agent_id = agent.unique_id
            self._grid[x, y] = agent_id
            self.agent_map[agent_id] = agent
        else:
            raise Exception("Cell not empty")

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef list get_cell_list_contents(self, list cell_list):
        length = len(cell_list)
        cdef long[:] out
        out = np.empty(length, long)

        cdef int count
        cdef long default_val
        cdef long x, y

        count = 0
        default_val = self.default_val()
        for i in range(length):
            pos = cell_list[i]
            x = pos[0]
            y = pos[1]
            if self._grid[x, y] == default_val:
                continue
            out[count] = self._grid[x, y]
            count += 1

        # return out[:count]

        cdef list out_list
        out_list = [0] * count
        for i in range(count):
            out_list[i] = self.agent_map[out[i]]
        return out_list

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef long[:] get_cell_list_contents_memoryview(self, long[:, :] cell_list):
        length = len(cell_list)
        cdef long[:] out
        out = np.empty(length, long)

        cdef int count
        cdef long default_val
        cdef long x, y

        count = 0
        default_val = self.default_val()
        for i in range(length):
            x, y = cell_list[i, 0], cell_list[i, 1]
            if self._grid[x, y] == default_val:
                continue
            out[count] = self._grid[x, y]
            count += 1

        return out[:count]

    # This get_neighborhood is identical to the
    # get_neighborhood in
    # https://github.com/rht/mesa_perf/blob/main/get_neighborhood/cython_grid.pyx
    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef list get_neighborhood(
        self,
        object pos,
        bint moore,
        #include_center: bool = False,
        int radius,
    ):
        cdef int x, y
        x, y = pos
        cdef int xfrom, xto
        cdef int yfrom, yto
        xfrom = max(0, x - radius)
        xto = min(self.width, x + radius + 1)
        yfrom = max(0, y - radius)
        yto = min(self.height, y + radius + 1)

        cdef int max_neighborhood_count
        max_neighborhood_count = (xto - xfrom) * (yto - yfrom)
        cdef long[:, :] neighborhood
        neighborhood = np.empty((max_neighborhood_count, 2), long)

        cdef int count
        cdef int nx, ny
        count = 0
        for nx in range(xfrom, xto):
            for ny in range(yfrom, yto):
                if not moore and abs(nx - x) + abs(ny - y) > radius:
                    continue
                neighborhood[count, 0] = nx
                neighborhood[count, 1] = ny
                count += 1


        # IF you want to return a NumPy array instead
        #return neighborhood[:count]

        # Convert to list
        cdef list neighborhood_list
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])

        return neighborhood_list

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef long[:, :] get_neighborhood_memoryview(
        self,
        object pos,
        bint moore,
        #include_center: bool = False,
        int radius,
    ):
        cdef int x, y
        x, y = pos
        cdef int xfrom, xto
        cdef int yfrom, yto
        xfrom = max(0, x - radius)
        xto = min(self.width, x + radius + 1)
        yfrom = max(0, y - radius)
        yto = min(self.height, y + radius + 1)

        cdef int max_neighborhood_count
        max_neighborhood_count = (xto - xfrom) * (yto - yfrom)
        cdef long[:, :] neighborhood
        neighborhood = np.empty((max_neighborhood_count, 2), long)

        cdef int count
        cdef int nx, ny
        count = 0
        for nx in range(xfrom, xto):
            for ny in range(yfrom, yto):
                if not moore and abs(nx - x) + abs(ny - y) > radius:
                    continue
                neighborhood[count, 0] = nx
                neighborhood[count, 1] = ny
                count += 1

        return neighborhood[:count]


cdef class GridLoL:
    cdef int height
    cdef int width
    cdef bint torus
    cdef int num_cells
    cdef list _grid_lol

    def __init__(self, width: int, height: int) -> None:
        self.height = height
        self.width = width
        #self.torus = torus
        self.num_cells = height * width

        self._grid_lol = [
            [self.default_val() for _ in range(self.height)] for _ in range(self.width)
        ]

    cpdef long default_val(self):
        return -1

    cpdef is_cell_empty(self, pos):
        cdef long x, y
        x, y = pos
        return self._grid_lol[x][y] == self.default_val()

    cpdef place_agent(self, agent, pos):
        cdef long x, y
        cdef int agent_id
        if self.is_cell_empty(pos):
            x, y = pos
            agent_id = agent.unique_id
            self._grid_lol[x][y] = agent
        else:
            raise Exception("Cell not empty")

    @cython.boundscheck(False)
    cpdef list get_cell_list_contents(self, list cell_list):
        length = len(cell_list)
        cdef object[:] out
        out = np.empty(length, object)

        cdef int count
        cdef long default_val
        cdef long x, y

        count = 0
        default_val = self.default_val()
        for i in range(length):
            x, y = cell_list[i]
            if self._grid_lol[x][y] == default_val:
                continue
            out[count] = self._grid_lol[x][y]
            count += 1

        cdef list out_list
        out_list = [0] * count
        for i in range(count):
            out_list[i] = out[i]
        return out_list

    # This get_neighborhood is identical to the
    # get_neighborhood in
    # https://github.com/rht/mesa_perf/blob/main/get_neighborhood/cython_grid.pyx
    @cython.boundscheck(False)
    cpdef list get_neighborhood(
        self,
        object pos,
        bint moore,
        #include_center: bool = False,
        int radius,
    ):
        cdef int x, y
        x, y = pos
        cdef int xfrom, xto
        cdef int yfrom, yto
        xfrom = max(0, x - radius)
        xto = min(self.width, x + radius + 1)
        yfrom = max(0, y - radius)
        yto = min(self.height, y + radius + 1)

        cdef int max_neighborhood_count
        max_neighborhood_count = (xto - xfrom) * (yto - yfrom)
        cdef long[:, :] neighborhood
        neighborhood = np.empty((max_neighborhood_count, 2), long)

        cdef int count
        cdef int nx, ny
        count = 0
        for nx in range(xfrom, xto):
            for ny in range(yfrom, yto):
                if not moore and abs(nx - x) + abs(ny - y) > radius:
                    continue
                neighborhood[count, 0] = nx
                neighborhood[count, 1] = ny
                count += 1


        # IF you want to return a NumPy array instead
        #return neighborhood[:count]

        # Convert to list
        cdef list neighborhood_list
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])

        return neighborhood_list

cdef class GridLoL2:
    cdef int height
    cdef int width
    cdef bint torus
    cdef int num_cells
    cdef object[:, :] _grid
    cdef dict agent_map

    def __init__(self, width: int, height: int) -> None:
        self.height = height
        self.width = width
        #self.torus = torus
        self.num_cells = height * width

        # self._grid = np.empty((self.width, self.height), self.default_val())
        self._grid = np.full((self.width, self.height), self.default_val(), dtype=object)

        self.agent_map = {}

    cpdef long default_val(self):
        return -1

    cpdef is_cell_empty(self, pos):
        cdef long x, y
        x, y = pos
        return self._grid[x, y] == self.default_val()

    cpdef place_agent(self, agent, pos):
        cdef long x, y
        cdef int agent_id
        if self.is_cell_empty(pos):
            x, y = pos
            agent_id = agent.unique_id
            self._grid[x, y] = agent
            self.agent_map[agent_id] = agent
        else:
            raise Exception("Cell not empty")

    @cython.boundscheck(False)
    #cpdef long[:] get_cell_list_contents(self, list cell_list):
    cpdef list get_cell_list_contents(self, list cell_list):
        length = len(cell_list)
        cdef list out
        out = [0] * length

        cdef int count
        cdef long default_val
        cdef long x, y

        count = 0
        default_val = self.default_val()
        for i in range(length):
            x, y = cell_list[i]
            #x = cell_list[i, 0]
            #y = cell_list[i, 1]
            if self._grid[x, y] == default_val:
                continue
            out[count] = self._grid[x, y]
            count += 1

        return out[:count]

    # This get_neighborhood is identical to the
    # get_neighborhood in
    # https://github.com/rht/mesa_perf/blob/main/get_neighborhood/cython_grid.pyx
    @cython.boundscheck(False)
    cpdef list get_neighborhood(
        self,
        object pos,
        bint moore,
        #include_center: bool = False,
        int radius,
    ):
        cdef int x, y
        x, y = pos
        cdef int xfrom, xto
        cdef int yfrom, yto
        xfrom = max(0, x - radius)
        xto = min(self.width, x + radius + 1)
        yfrom = max(0, y - radius)
        yto = min(self.height, y + radius + 1)

        cdef int max_neighborhood_count
        max_neighborhood_count = (xto - xfrom) * (yto - yfrom)
        cdef long[:, :] neighborhood
        neighborhood = np.empty((max_neighborhood_count, 2), long)

        cdef int count
        cdef int nx, ny
        count = 0
        for nx in range(xfrom, xto):
            for ny in range(yfrom, yto):
                if not moore and abs(nx - x) + abs(ny - y) > radius:
                    continue
                neighborhood[count, 0] = nx
                neighborhood[count, 1] = ny
                count += 1


        # IF you want to return a NumPy array instead
        #return neighborhood[:count]

        # Convert to list
        cdef list neighborhood_list
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])

        return neighborhood_list
