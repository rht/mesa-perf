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

from numba_version import get_neighborhood

get_neighborhood(30, 30, (10, 10), True, 10)
# print(get_neighborhood.inspect_types())
tic = time.time()
for i in range(repetition):
    get_neighborhood(30, 30, (10, 10), True, 10)
print("numba", (time.time() - tic) / repetition * 1e6, "μs")
