import timeit

repetition = 1000

def print_elapsed(label, setup, stmt):
    _elapsed = timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    elapsed = "{:.3f} μs".format(_elapsed)
    print(label, elapsed)
    return _elapsed

setup = """
import mesa
import random
random.seed(1)
width = 100
height = 100
grid = mesa.space.SingleGrid(width, height, False)
for i in range(10000):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius=10)
"""

stmt = "mesa.space.SingleGrid(width, height, False)"
print_elapsed("python grid __init__", setup, stmt)

stmt = "grid._neighborhood_cache = {}; grid.get_neighborhood((10, 10), True, include_center=True, radius=10)"
elapsed_neighborhood_default = print_elapsed("python get_neighborhood", setup, stmt)

stmt = "grid.get_cell_list_contents(cell_list)"
elapsed_cl_default = print_elapsed("python get_cell_list_contents", setup, stmt)

setup = """
import mesa
from space import {0}
import random
random.seed(1)
width = 100
height = 100
grid = {0}(width, height, False)
for i in range(10000):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius=10)
"""

stmt = "_Grid(width, height, False)"
print_elapsed("cython with map grid __init__", setup.format("_Grid"), stmt)

stmt = "grid.get_neighborhood((10, 10), True, include_center=True, radius=10)"
elapsed_neighborhood_cython = print_elapsed("cython with map get_neighborhood", setup.format("_Grid"), stmt)
print("  speedup", round(elapsed_neighborhood_default / elapsed_neighborhood_cython, 2))

stmt = "grid.get_cell_list_contents(cell_list)"
elapsed_cl_cython = print_elapsed("cython with map get_cell_list_contents", setup.format("_Grid"), stmt)
print("  speedup", round(elapsed_cl_default / elapsed_cl_cython, 2))

stmt = "_Grid_NoMap(width, height, False)"
print_elapsed("cython grid __init__", setup.format("_Grid_NoMap"), stmt)

stmt = "grid.get_neighborhood((10, 10), True, include_center=True, radius=10)"
elapsed_neighborhood_nomap = print_elapsed("cython get_neighborhood", setup.format("_Grid_NoMap"), stmt)
print("  speedup", round(elapsed_neighborhood_default / elapsed_neighborhood_nomap, 2))

stmt = "grid.get_cell_list_contents(cell_list)"
elapsed_cl_nomap = print_elapsed("cython get_cell_list_contents", setup.format("_Grid_NoMap"), stmt)
print("  speedup", round(elapsed_cl_default / elapsed_cl_nomap, 2))
