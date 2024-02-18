# cython: infer_types=True
import itertools
from typing import Tuple

cimport cython
import numpy as np

Coordinate = Tuple[int, int]

cdef class Grid:
    """Base class for a rectangular grid.

    Grid cells are indexed by [x][y], where [0][0] is assumed to be the
    bottom-left and [width-1][height-1] is the top-right. If a grid is
    toroidal, the top and bottom, and left and right, edges wrap to each other

    Properties:
        width, height: The grid's width and height.
        torus: Boolean which determines whether to treat the grid as a torus.
        grid: Internal list-of-lists which holds the grid cells themselves.
    """

    cdef int height
    cdef int width
    cdef bint torus
    cdef int num_cells
    cdef long[:, :] grid

    def __init__(self, width: int, height: int) -> None:
        """Create a new grid.

        Args:
            width, height: The width and height of the grid
            torus: Boolean whether the grid wraps or not.
        """
        self.height = height
        self.width = width
        #self.torus = torus
        self.num_cells = height * width

        # self.grid = np.empty((self.width, self.height), self.default_val())
        self.grid = np.full((self.width, self.height), self.default_val(), dtype=long)
        #[
        #    [self.default_val() for _ in range(self.height)] for _ in range(self.width)
        #]

        # Add all cells to the empties list.
        # self.empties = set(itertools.product(range(self.width), range(self.height)))

        # Neighborhood Cache
        #self._neighborhood_cache: dict[Any, list[Coordinate]] = dict()

    def default_val(self):
        """Default value for new cell elements."""
        return -1

    #@cython.boundscheck(False)
    #@cython.wraparound(False)
    cpdef list get_neighborhood(
        self,
        object pos,
        bint moore,
        bint include_center,
        int radius,
        bint torus,
    ):

        cdef int x, y
        x, y = pos

        cdef int max_neighborhood_count
        max_neighborhood_count = (2 * radius + 1) ** 2
        cdef long[:, :] neighborhood
        neighborhood = np.empty((max_neighborhood_count, 2), long)

        cdef int count
        count = 0
        cdef int new_x, new_y
        cdef int dx, dy
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                if not moore and abs(dx) + abs(dy) > radius:
                    continue
                new_x = x + dx
                new_y = y + dy

                if torus:
                    new_x %= self.width
                    new_y %= self.height
                elif self.out_of_bounds((new_x, new_y)):
                    continue

                if not (not include_center and dx == 0 and dy == 0):
                    neighborhood[count, 0] = new_x
                    neighborhood[count, 1] = new_y
                    count += 1

        # Convert to list
        cdef list neighborhood_list
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])

        return neighborhood_list

    #@cython.boundscheck(False)
    #@cython.wraparound(False)
    cpdef list get_neighborhood_old_method(
        self,
        object pos,
        bint moore,
        #include_center: bool = False,
        int radius,
    ):
        #cache_key = (pos, moore, include_center, radius)
        #neighborhood = self._neighborhood_cache.get(cache_key, None)

        #if neighborhood is not None:
        #    return neighborhood

        # We use a list instead of a dict for the neighborhood because it would
        # be easier to port the code to Cython or Numba (for performance
        # purpose), with minimal changes. To better understand how the
        # algorithm was conceived, look at
        # https://github.com/projectmesa/mesa/pull/1476#issuecomment-1306220403
        # and the discussion in that PR in general.
        #neighborhood = []

        #assert not self.torus

        # cdef int radius

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

        #if not include_center and neighborhood:
        #    neighborhood.remove(pos)

        #self._neighborhood_cache[cache_key] = neighborhood

        # IF you want to return a NumPy array instead
        #return neighborhood[:count]

        # Convert to list
        cdef list neighborhood_list
        neighborhood_list = [0] * count
        for i in range(count):
            neighborhood_list[i] = (neighborhood[i, 0], neighborhood[i, 1])

        return neighborhood_list

    def torus_adj(self, pos: Coordinate) -> Coordinate:
        """Convert coordinate, handling torus looping."""
        if not self.out_of_bounds(pos):
            return pos
        elif not self.torus:
            raise Exception("Point out of bounds, and space non-toroidal.")
        else:
            return pos[0] % self.width, pos[1] % self.height

    cpdef bint out_of_bounds(self, pos: Coordinate):
        """Determines whether position is off the grid, returns the out of
        bounds coordinate."""
        cdef int x, y
        x, y = pos
        return x < 0 or x >= self.width or y < 0 or y >= self.height
