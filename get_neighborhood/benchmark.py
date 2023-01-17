import timeit

repetition = 1000

def time_elapsed(setup, stmt, repetition):
    return "{:.3f} μs".format(timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition)

setup = """
from mesa.space import Grid
grid = Grid(30, 30, True)
"""
stmt = "grid._neighborhood_cache = {}; grid.get_neighborhood((10, 10), True, True, 10)"
print("default", time_elapsed(setup, stmt, repetition))

setup = """
def empty():
    return
"""
stmt = "empty()"
print("empty python", time_elapsed(setup, stmt, repetition))

setup = """
import cython_grid
grid2 = cython_grid.Grid(30, 30, False)
"""
stmt = "grid2.get_neighborhood((10, 10), True, 10)"
print("cython np.array", time_elapsed(setup, stmt, repetition))

setup = "import tortar"
stmt = "tortar.compute_neighborhood((10, 10), True, True, 10, False, 30, 30)"
print("cython list", time_elapsed(setup, stmt, repetition))

setup = "from numba_version import get_neighborhood; get_neighborhood(30, 30, (10, 10), True, 10)"
stmt = "get_neighborhood(30, 25, (10, 10), True, 10)"
print("numba np.array", time_elapsed(setup, stmt, repetition))

setup = "from numba_version import get_neighborhood_typed_list"
stmt = "get_neighborhood_typed_list(30, 30, (10, 10), True, 10)"
print("numba typed_list", time_elapsed(setup, stmt, repetition))

setup = "from cython_array import compute_neighborhood_array"
stmt = "compute_neighborhood_array((10, 10), True, 10, 30, 30)"
print("cython array", time_elapsed(setup, stmt, repetition))
