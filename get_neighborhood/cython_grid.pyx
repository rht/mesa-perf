# cython: infer_types=True
import itertools

cimport cython
import numpy as np

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

    def __init__(self, width: int, height: int, torus: bint) -> None:
        """Create a new grid.

        Args:
            width, height: The width and height of the grid
            torus: Boolean whether the grid wraps or not.
        """
        self.height = height
        self.width = width
        self.torus = torus
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

    cpdef char default_val(self):
        """Default value for new cell elements."""
        return -1
 
    @cython.wraparound(False)
    @cython.boundscheck(False)
    cpdef int[:, :] get_neighborhood(self, object pos, bint moore, bint include_center, int radius):

        cdef int[:, :] neighborhood
        cdef int x_radius, y_radius, dx, dy, nx, ny, kx, ky
        cdef int min_x_range, max_x_range, min_y_range, max_y_range
        cdef int x, y, count
        
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

        return neighborhood[:count]

    def torus_adj(self, pos: Coordinate) -> Coordinate:
        """Convert coordinate, handling torus looping."""
        if not self.out_of_bounds(pos):
            return pos
        elif not self.torus:
            raise Exception("Point out of bounds, and space non-toroidal.")
        else:
            return pos[0] % self.width, pos[1] % self.height

    def out_of_bounds(self, pos: Coordinate) -> bool:
        """Determines whether position is off the grid, returns the out of
        bounds coordinate."""
        x, y = pos
        return x < 0 or x >= self.width or y < 0 or y >= self.height
