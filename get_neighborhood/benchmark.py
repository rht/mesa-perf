import time

#import mesa
import pure_python

repetition = 1000

#grid = mesa.space.SingleGrid(30, 30, False)
#tic = time.time()
#for i in range(30):
#    grid._neighborhood_cache = {}
#    grid.get_neighborhood((10, 10), True, include_center=True, radius=10)
#print("default", time.time() - tic)
tic = time.time()
for i in range(repetition):
    pure_python.get_neighborhood((10, 10), True, True, 10, False, 30, 30)
print("default", (time.time() - tic) / repetition * 1e6, "μs")

def empty():
    return

tic = time.time()
for i in range(repetition):
    empty()
print("Empty function", (time.time() - tic) / repetition * 1e6, "μs")

import cython_grid

grid2 = cython_grid.Grid(30, 30)
tic = time.time()
for i in range(repetition):
    grid2.get_neighborhood((10, 10), True, 10)
print("cython", (time.time() - tic) / repetition * 1e6, "μs")

import tortar
tic = time.time()
for i in range(repetition):
    tortar.compute_neighborhood((10, 10), True, True, 10, False, 30, 30)
print("tortar", (time.time() - tic) / repetition * 1e6, "μs")

import numpy as np
import numba as nb
from numba import types

locals = {
    "x": types.int64,
    "y": types.int64,
    "xfrom": types.int64,
    "xto": types.int64,
    "yfrom": types.int64,
    "yto": types.int64,
    "count": types.int64,
}
# @nb.njit(nb.int64[:, :](nb.int64, nb.int64, nb.int64[:], nb.boolean, nb.int64), cache=True, locals=locals)
@nb.njit(cache=True, locals=locals)
def get_neighborhood(height, width, pos, moore, radius):
    x, y = pos
    xfrom = max(0, x - radius)
    xto = min(width, x + radius + 1)
    yfrom = max(0, y - radius)
    yto = min(height, y + radius + 1)

    max_neighborhood_count = (xto - xfrom) * (yto - yfrom)
    neighborhood = np.empty((max_neighborhood_count, 2), np.int64)

    count = 0
    for nx in range(xfrom, xto):
        for ny in range(yfrom, yto):
            if not moore and abs(nx - x) + abs(ny - y) > radius:
                continue
            neighborhood[count, 0] = nx
            neighborhood[count, 1] = ny
            count += 1

    return neighborhood[:count]


get_neighborhood(30, 30, (10, 10), True, 10)
# print(get_neighborhood.inspect_types())
tic = time.time()
for i in range(repetition):
    get_neighborhood(30, 30, (10, 10), True, 10)
print("numba", (time.time() - tic) / repetition * 1e6, "μs")
