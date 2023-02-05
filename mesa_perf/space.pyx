# cython: infer_types=True
# cython: language_level=3
# cython: nonecheck=False
# cython: initializedcheck=False

import numpy as np
import itertools

cdef is_integer(x):
    return isinstance(x, int) or isinstance(x, np.integer)


cdef class _Grid:

    cdef readonly long height, width, num_cells, num_empties
    cdef readonly bint torus
    cdef list _grid
    cdef char[:, :] _occupancy_matrix
    cdef dict _neighborhood_cache
    cdef bint _empties_built 
    cdef set _empties
    
    def __init__(self, long width, long height, bint torus):
        
        self.height = height
        self.width = width
        self.torus = torus
        self.num_cells = height * width
        self.num_empties = self.num_cells
        
        self._occupancy_matrix = np.zeros((self.width, self.height), dtype=np.int8)

        self._grid = [
            [self.default_val() for _ in range(self.height)] for _ in range(self.width)
        ]
        
        self._empties_built = False
        self._neighborhood_cache = {}

    cpdef default_val(self):
        return None

    @property
    def empties(self):
        if not self._empties_built:
            self._build_empties()
        return self._empties

    cdef _build_empties(self):
        self._empties = set()
        for x in range(self.width):
            for y in range(self.height):
                pos = (x, y)
                if self.is_cell_empty(pos):
                    self._empties.add(pos)
        self._empties_built = True

    def __getitem__(self, index):
        
        if isinstance(index, tuple):
            x, y = index
            x_int, y_int = is_integer(x), is_integer(y)
            if x_int and y_int:
                # grid[x, y]
                x, y = self.torus_adj(index)
                return self._grid[x][y]
            elif x_int:
                # grid[x, :]
                x, _ = self.torus_adj((x, 0))
                return self._grid[x][y]
            elif y_int:
                # grid[:, y]
                _, y = self.torus_adj((0, y))
                return [rows[y] for rows in self._grid[x]]
            else:
                # grid[:, :]
                return [cell for rows in self._grid[x] for cell in rows[y]]
        elif isinstance(index[0], tuple):
            # grid[(x1, y1), (x2, y2), ...]
            return [self._grid[x][y] for x, y in map(self.torus_adj, index)]
        else:
            # grid[x]
            return self._grid[index]
            
    cpdef list get_neighborhood(self, object pos, bint moore, bint include_center = False, int radius = 1):
        cdef list neighborhood
        cdef long nx, ny
        cdef int n, x_radius, y_radius, dx, dy, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count
        
        cache_key = (pos, moore, include_center, radius)
        neighborhood = self._neighborhood_cache.get(cache_key, None)
        
        if neighborhood:
            return neighborhood
        
        x, y = pos
        count = 0
        if self.torus:
            x_max_radius, y_max_radius = self.width // 2, self.height // 2
            x_radius, y_radius = min(radius, x_max_radius), min(radius, y_max_radius)

            xdim_even, ydim_even = (self.width + 1) % 2, (self.height + 1) % 2
            kx = 1 if x_radius == x_max_radius and xdim_even else 0
            ky = 1 if y_radius == y_max_radius and ydim_even else 0
            
            n = (2 * x_radius + 1 - kx) * (2 * y_radius + 1 - ky) 
            neighborhood = [None] * n
            for dx in range(-x_radius, x_radius + 1 - kx):
                for dy in range(-y_radius, y_radius + 1 - ky):

                    if not moore and abs(dx) + abs(dy) > radius:
                        continue

                    nx = (x + dx) % self.width
                    ny = (y + dy) % self.height

                    if nx == x and ny == y and not include_center:
                        continue
                    
                    neighborhood[count] = (nx, ny)
                    count += 1
        else:
            min_x_range = max(0, x - radius)
            max_x_range = min(self.width, x + radius + 1)
            min_y_range = max(0, y - radius)
            max_y_range = min(self.height, y + radius + 1)
            
            n = (max_x_range-min_x_range) * (max_y_range-min_y_range)
            neighborhood = [None] * n
            for nx in range(min_x_range, max_x_range):
                for ny in range(min_y_range, max_y_range):

                    if not moore and abs(nx - x) + abs(ny - y) > radius:
                        continue

                    if nx == x and ny == y and not include_center:
                        continue

                    neighborhood[count] = (nx, ny)
                    count += 1
        
        neighborhood = neighborhood[:count]
        self._neighborhood_cache[cache_key] = neighborhood
        
        return neighborhood

    cpdef list get_neighbors(self, pos, bint moore, bint include_center = False, int radius = 1):
        neighbors = self.get_neighborhood(pos, moore, include_center, radius)
        return self.get_cell_list_contents(neighbors)

    cpdef tuple torus_adj(self, pos):
        cdef long x, y
        if not self.out_of_bounds(pos):
            return pos
        elif not self.torus:
            raise Exception("Point out of bounds, and space non-toroidal.")
        else:
            x, y = pos
            return x % self.width, y % self.height

    cpdef bint out_of_bounds(self, pos):
        cdef long x, y
        x, y = pos
        return x < 0 or x >= self.width or y < 0 or y >= self.height

    cpdef list get_cell_list_contents(self, cell_list):
        cdef list agents
        cdef long count
        
        if (length:=len(cell_list)) == 2 and isinstance(cell_list, tuple):
            cell_list = [cell_list]
            
        agents = [None] * length
        count = 0

        for pos in cell_list:
            if not self.is_cell_empty(pos):
                x, y = pos
                agents[count] = self._grid[x][y]
                count += 1
                
        return agents[:count]

    cpdef place_agent(self, agent, pos):
        ...

    cpdef remove_agent(self, agent):
        ...

    cpdef move_agent(self, agent, pos):
        pos = self.torus_adj(pos)
        self.remove_agent(agent)
        self.place_agent(agent, pos)

    cpdef swap_pos(self, agent_a, agent_b):
        agents_no_pos = []
        pos_a, pos_b = agent_a.pos, agent_b.pos
        if pos_a is None:
            agents_no_pos.append(agent_a)
        if pos_b is None:
            agents_no_pos.append(agent_b)
        if agents_no_pos:
            agents_no_pos = [f"<Agent id: {a.unique_id}>" for a in agents_no_pos]
            raise Exception(f"{', '.join(agents_no_pos)} - not on the grid")

        if pos_a == pos_b:
            return

        self.remove_agent(agent_a)
        self.remove_agent(agent_b)

        self.place_agent(agent_a, pos_b)
        self.place_agent(agent_b, pos_a)

    cpdef bint is_cell_empty(self, pos):
        cdef long x, y
        
        x, y = pos
        return self._occupancy_matrix[x, y] == 0

    cpdef move_to_empty(self, agent, double cutoff = 0.998):
        cdef long num_empty_cells
        
        num_empty_cells = self.num_empties
        if num_empty_cells == 0:
            raise Exception("ERROR: No empty cells")

        if 1 - num_empty_cells / self.num_cells < cutoff:
            while True:
                new_pos = (
                    agent.random.randrange(self.width),
                    agent.random.randrange(self.height),
                )
                if self.is_cell_empty(new_pos):
                    break
        else:
            new_pos = agent.random.choice(sorted(self.empties))
        self.move_agent(agent, new_pos)

    cpdef bint exists_empty_cells(self):
        return self.num_empties > 0
        
    def iter_cell_list_contents(self, cell_list) :
        if len(cell_list) == 2 and isinstance(cell_list, tuple):
            cell_list = [cell_list]
        return (self._grid[x][y] for x, y in itertools.filterfalse(self.is_cell_empty, cell_list))

    cpdef iter_neighbors(self, pos, bint moore, bint include_center = False, int radius = 1):
        neighborhood = self.get_neighborhood(pos, moore, include_center, radius)
        return self.iter_cell_list_contents(neighborhood)
        
    def __iter__(self):
        return itertools.chain(*self._grid)

    def coord_iter(self):
        for row in range(self.width):
            for col in range(self.height):
                yield self._grid[row][col], row, col  # agent, x, y

cdef class SingleGrid(_Grid):

    cpdef place_agent(self, agent, pos):
        cdef long x, y
        if self.is_cell_empty(pos):
            x, y = pos
            self._occupancy_matrix[x, y] = 1
            self.num_empties -= 1
            self._grid[x][y] = agent
            if self._empties_built:
                self._empties.discard(pos)
            agent.pos = pos
        else:
            raise Exception("Cell not empty")

    cpdef remove_agent(self, agent):
        cdef long x, y
        pos = agent.pos
        if pos is None:
            return
        x, y = pos
        self._occupancy_matrix[x, y] = 0
        self.num_empties += 1
        self._grid[x][y] = self.default_val()
        if self._empties_built:
            self._empties.add(pos)
        agent.pos = None


cdef class MultiGrid(_Grid):

    cpdef default_val(self):
        return []

    cpdef place_agent(self, agent, pos):
        cdef long x, y
        x, y = pos
        if agent.pos is None or agent not in self._grid[x][y]:
            if self.is_cell_empty(pos):
                self._occupancy_matrix[x, y] = 1
                self.num_empties -= 1
            self._grid[x][y].append(agent)
            agent.pos = pos
            if self._empties_built:
                self._empties.discard(pos)

    cpdef remove_agent(self, agent):
        cdef long x, y
        pos = agent.pos
        x, y = pos
        self._grid[x][y].remove(agent)
        if self.is_cell_empty(pos):
            self.num_empties += 1
            self._occupancy_matrix[x, y] = 0
            if self._empties_built:
                self._empties.add(pos)
        agent.pos = None
    
    cpdef list get_cell_list_contents(self, cell_list):
        
        cdef list agents
        
        if len(cell_list) == 2 and isinstance(cell_list, tuple):
            cell_list = [cell_list]
            
        agents = []

        for pos in cell_list:
            if not self.is_cell_empty(pos):
                x, y = pos
                agents_cell = self._grid[x][y]
                for j in range(len(agents_cell)):
                    agent = agents_cell[j]
                    agents.append(agent)
                
        return agents
    
    def iter_cell_list_contents(self, cell_list):
        if len(cell_list) == 2 and isinstance(cell_list, tuple):
            cell_list = [cell_list]
            
        for pos in cell_list:
            if not self.is_cell_empty(pos):
                x, y = pos
                for content in self._grid[x][y]:
                    yield content
                    
                    
cdef class _Grid_memviews:
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
        
