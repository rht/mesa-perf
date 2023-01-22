import timeit

repetition = 1000

def time_elapsed(label, setup, stmt):
    _elapsed = timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    print(label, "{:.3f} μs".format(_elapsed))
    return _elapsed

setup = """import pure_python"""
stmt = "pure_python.get_neighborhood((10, 10), True, True, 10, False, 30, 30)"
elapsed_default = time_elapsed("default", setup, stmt)

setup = """
def empty():
    return
"""
stmt = "empty()"
time_elapsed("python empty", setup, stmt)

setup = """
import cython_grid
grid2 = cython_grid.Grid(30, 30)
"""
stmt = "grid2.get_neighborhood((10, 10), True, 10)"
elapsed_cython_ndarray = time_elapsed("cython np.array", setup, stmt)
print("  faster", round(elapsed_default / elapsed_cython_ndarray, 2))

setup = "import tortar"
stmt = "tortar.compute_neighborhood((10, 10), True, True, 10, False, 30, 30)"
time_elapsed("cython list", setup, stmt)

setup = "from numba_version import get_neighborhood; get_neighborhood(30, 30, (10, 10), True, 10)"
stmt = "get_neighborhood(30, 25, (10, 10), True, 10)"
time_elapsed("numba np.array", setup, stmt)

setup = "from numba_version import get_neighborhood_typed_list"
stmt = "get_neighborhood_typed_list(30, 30, (10, 10), True, 10)"
time_elapsed("numba typed_list", setup, stmt)

setup = "from cython_array import compute_neighborhood_array"
stmt = "compute_neighborhood_array((10, 10), True, 10, 30, 30)"
time_elapsed("cython array", setup, stmt)
