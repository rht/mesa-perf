import timeit

repetition = 1000
grid_size = "100, 100"
pos = "(50, 50)"
radius = 3

# import mesa
# def foo():
#     for i in range(1000):
#         mesa.get_neighborhood_vector((50, 50), True, True, 50, False, 100, 100)
#         print(i)
# foo()
# exit()

def time_elapsed(label, setup, stmt):
    _elapsed = timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    print(label, "{:.3f} μs".format(_elapsed))
    return _elapsed

if 1:
    setup = """import pure_python"""
    stmt = f"pure_python.get_neighborhood({pos}, True, True, {radius}, False, {grid_size})"
    elapsed_default = time_elapsed("default (pure python)", setup, stmt)

    setup = """
def empty():
    return
    """
    stmt = "empty()"
    time_elapsed("python empty", setup, stmt)

if 1:
    # Cython
    print()
    setup = f"""
import cython_grid
grid2 = cython_grid.Grid({grid_size})
    """
    stmt = f"grid2.get_neighborhood_vector({pos}, True, True, {radius}, False)"
    elapsed_cython_ndarray = time_elapsed("cython vector", setup, stmt)
    print("  faster", round(elapsed_default / elapsed_cython_ndarray, 2), "X")

    stmt = f"grid2.get_neighborhood_old_method({pos}, True, {radius})"
    elapsed_cython_ndarray = time_elapsed("cython old less-readable", setup, stmt)
    print("  faster", round(elapsed_default / elapsed_cython_ndarray, 2), "X")

# Rust
print()
setup = """
import mesa
"""
# stmt = f"mesa.get_neighborhood_hashmap({pos}, True, True, {radius}, False, {grid_size})"
# elapsed_rust = time_elapsed("rust hashmap", setup, stmt)
# print("  faster", round(elapsed_default / elapsed_rust, 2), "X")

stmt = f"mesa.get_neighborhood_vector({pos}, True, True, {radius}, False, {grid_size})"
elapsed_rust = time_elapsed("rust vector", setup, stmt)
print("  faster", round(elapsed_default / elapsed_rust, 2), "X")

stmt = f"mesa.get_neighborhood_old_method({pos}, True, {radius}, {grid_size})"
elapsed_rust = time_elapsed("rust old less-readable", setup, stmt)
print("  faster", round(elapsed_default / elapsed_rust, 2), "X")

exit()
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
