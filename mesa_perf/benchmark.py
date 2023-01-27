import timeit

repetition = 1000
radius = 10
density = 0.5

def elapsed(setup, stmt):
    _elapsed = timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    return _elapsed

setup = """
import mesa
import random
random.seed(1)
density = {0}
width = 100
height = 100
grid = mesa.space.SingleGrid(width, height, False)
for i in range(round(density*width*height)):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius={1})
""".format(density, radius)

print("\nTimings Default\n")


methods = ["__init__(width, height, False)", "get_neighborhood((10, 10), True, include_center=True, radius={})".format(radius), 
           "get_cell_list_contents(cell_list)", "get_neighbors((10, 10), True, include_center=True, radius={})".format(radius), 
           "get_neighborhood((10, 10), True, include_center=True, radius={})".format(radius), 
           "get_cell_list_contents(cell_list)", "get_neighbors((10, 10), True, include_center=True, radius={})".format(radius)]

elapsed_methods_default = []
for method_with_params in methods:
    stmt = "grid.{}".format(method_with_params)
    method = method_with_params.split("(")[0]
    time_method = elapsed(setup, stmt)
    elapsed_methods_default.append((method, time_method))
    
n = 4
for x, y in list(elapsed_methods_default)[:n]: 
    str_elapsed = "{:.2f} μs".format(y)
    print("Grid Default", x, str_elapsed)

setup = """
import mesa
from space import {0}
import random
random.seed(1)
density = {1}
width = 100
height = 100
grid = {0}(width, height, False)
for i in range(round(density*width*height)):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius={2})
#print(cell_list)
cell_view = grid.convert_tuples_to_mview(cell_list)
""".format("_Grid", density, radius)

descr = "Cython Agents+Ids "
print("\nTimings", descr, "\n")

methods = ["__init__(width, height, False)", "get_neighborhood((10, 10), True, include_center=True, radius={})".format(radius), 
           "get_cell_list_contents(cell_list)", "get_neighbors((10, 10), True, include_center=True, radius={})".format(radius),
           "get_neighborhood_mview((10, 10), True, include_center=True, radius={})".format(radius),
           "get_cell_mview_contents(cell_view)", "get_neighbors_mview((10, 10), True, include_center=True, radius={})".format(radius)]

elapsed_methods_grid_double = []

for method_with_params in methods:
    stmt = "grid.{}".format(method_with_params)
    method = method_with_params.split("(")[0]
    time_method = elapsed(setup, stmt)
    elapsed_methods_grid_double.append((method, time_method))
    

for (x, y), (z, h) in zip(elapsed_methods_default, elapsed_methods_grid_double): 

    str_elapsed = "{:.2f} μs".format(h)
    speed_up = "{:.2f}".format(y/h)

    print("Grid Agents+Ids", z, str_elapsed, " --> speedup", speed_up)


setup = """
import mesa
from space import {0}
import random
random.seed(1)
density = {1}
width = 100
height = 100
grid = {0}(width, height, False)
for i in range(round(density*width*height)):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius={2})
#print(cell_list)
cell_view = grid.convert_tuples_to_mview(cell_list)
""".format("_Grid_NoMap", density, radius)

descr = "Cython Only Agents "
print("\nTimings", descr, "\n")

methods = ["__init__(width, height, False)", "get_neighborhood((10, 10), True, include_center=True, radius={})".format(radius), 
           "get_cell_list_contents(cell_list)", "get_neighbors((10, 10), True, include_center=True, radius={})".format(radius),
           "get_neighborhood_mview((10, 10), True, include_center=True, radius={})".format(radius),
           "get_cell_mview_contents(cell_view)", "get_neighbors_mview((10, 10), True, include_center=True, radius={})".format(radius)]

elapsed_methods_grid_single = []

for method_with_params in methods:
    stmt = "grid.{}".format(method_with_params)
    method = method_with_params.split("(")[0]
    time_method = elapsed(setup, stmt)
    elapsed_methods_grid_single.append((method, time_method))

for (x, y), (z, h) in zip(elapsed_methods_default, elapsed_methods_grid_single): 

    str_elapsed = "{:.2f} μs".format(h)
    speed_up = "{:.2f}".format(y/h)

    print("Grid Agents", z, str_elapsed, " --> speedup", speed_up)
