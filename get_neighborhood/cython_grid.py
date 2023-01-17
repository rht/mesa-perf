# cython: infer_types=True

import cython
import numpy as np

@cython.cclass
class Grid:
    """Base class for a rectangular grid.

    Grid cells are indexed by [x][y], where [0][0] is assumed to be the
    bottom-left and [width-1][height-1] is the top-right. If a grid is
    toroidal, the top and bottom, and left and right, edges wrap to each other

    Properties:
        width, height: The grid's width and height.
        torus: Boolean which determines whether to treat the grid as a torus.
        grid: Internal list-of-lists which holds the grid cells themselves.
    """

    height = cython.declare(cython.int, visibility='readonly')
    width = cython.declare(cython.int, visibility='readonly')
    num_cells = cython.declare(cython.int, visibility='readonly')
    torus = cython.declare(cython.bint, visibility='readonly')
    grid: cython.int[:, :]

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

        self.grid = np.full((self.width, self.height), self.default_val(), dtype=cython.int)

    @cython.ccall
    def default_val(self) -> cython.char:
        """Default value for new cell elements."""
        return -1

    @cython.ccall
    @cython.wraparound(False)
    @cython.boundscheck(False)
    def get_neighborhood(self, pos, moore: cython.bint, radius: cython.int = 1, include_center: cython.bint = False) ->  cython.int[:, :]:

        x: cython.int; y: cython.int
        x, y = pos[0], pos[1]

        neighborhood = np.empty(((radius + 2) ** 2, 2), cython.int)

        count: cython.int
        count = 0

        if self.torus:
            x_max_radius, y_max_radius = self.width // 2, self.height // 2

            x_radius: cython.int; y_radius: cython.int
            x_radius, y_radius = min(radius, x_max_radius), min(radius, y_max_radius)

            xdim_even, ydim_even = (self.width + 1) % 2, (self.height + 1) % 2
            kx: cython.int = 1 if x_radius == x_max_radius and xdim_even else 0
            ky: cython.int = 1 if y_radius == y_max_radius and ydim_even else 0

            dx: cython.int; dy: cython.int
            nx: cython.int; ny: cython.int
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
            min_x_range: cython.int = max(0, x - radius)
            max_x_range: cython.int = min(self.width, x + radius + 1)
            min_y_range: cython.int = max(0, y - radius)
            max_y_range: cython.int = min(self.height, y + radius + 1)

            nx: cython.int; ny: cython.int
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

    def torus_adj(self, pos):
        """Convert coordinate, handling torus looping."""
        if not self.out_of_bounds(pos):
            return pos
        elif not self.torus:
            raise Exception("Point out of bounds, and space non-toroidal.")
        else:
            return pos[0] % self.width, pos[1] % self.height

    def out_of_bounds(self, pos) -> bool:
        """Determines whether position is off the grid, returns the out of
        bounds coordinate."""
        x, y = pos
        return x < 0 or x >= self.width or y < 0 or y >= self.height
