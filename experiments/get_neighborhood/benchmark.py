import time

#import mesa
import pure_python

repetition = 1000

def print_elapsed(label):
    global tic
    print(label, round((time.time() - tic) / repetition * 1e6, 3), "μs")

#grid = mesa.space.SingleGrid(30, 30, False)
#tic = time.time()
#for i in range(30):
#    grid._neighborhood_cache = {}
#    grid.get_neighborhood((10, 10), True, include_center=True, radius=10)
#print("default", time.time() - tic)
tic = time.time()
for i in range(repetition):
    a = pure_python.get_neighborhood((10, 10), True, True, 10, False, 30, 30)
    [j for j in a]
print_elapsed("default")

def empty():
    return

tic = time.time()
for i in range(repetition):
    empty()
print_elapsed("empty_function")

import cython_grid

grid2 = cython_grid.Grid(30, 30)
tic = time.time()
for i in range(repetition):
    a = grid2.get_neighborhood((10, 10), True, 10)
    [j for j in a]
print_elapsed("cython np.ndarray")

import tortar
tic = time.time()
for i in range(repetition):
    a = tortar.compute_neighborhood((10, 10), True, True, 10, False, 30, 30)
    [j for j in a]
print_elapsed("cython list")

from numba_version import get_neighborhood, get_neighborhood_typed_list

get_neighborhood(30, 30, (10, 10), True, 10)
# print(get_neighborhood.inspect_types())
tic = time.time()
for i in range(repetition):
    a = get_neighborhood(30, 30, (10, 10), True, 10)
    [j for j in a]
print_elapsed("numba np.ndarray")

get_neighborhood_typed_list(30, 30, (10, 10), True, 10)
tic = time.time()
for i in range(repetition):
    a = get_neighborhood_typed_list(30, 30, (10, 10), True, 10)
    [j for j in a]
print_elapsed("numba typed list")

from cython_array import compute_neighborhood_array
tic = time.time()
for i in range(repetition):
    a = compute_neighborhood_array((10, 10), True, 10, 30, 30)
    #list(zip(*a))
print_elapsed("cython array")
