import timeit

repetition = 1000
radius = 10
density = 0.5

def print_elapsed(label, setup, stmt):
    _elapsed = timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    elapsed = "{:.3f} μs".format(_elapsed)
    print(label, elapsed, end="")
    return _elapsed

setup = """
import mesa
import random
random.seed(1)
density = {0}
width = 200
height = 200
grid = mesa.space.SingleGrid(width, height, False)
model = mesa.Model()
for i in range(round(density*width*height)):
    agent = mesa.Agent(i, model)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
pos = (x,y)
cell_list = grid.get_neighborhood(pos, True, include_center=False, radius={1})
""".format(density, radius)

print("\ntimings default\n")

descr = "python grid "

stmt = "mesa.space.SingleGrid(width, height, False)"
method = "__init__"
elapsed_init_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "grid.get_neighborhood(pos, True, include_center=False, radius={})".format(radius)
method = "get_neighborhood"
elapsed_get_neighborhood_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "grid.get_cell_list_contents(cell_list)"
method = "get_cell_list_contents"
elapsed_get_cell_list_contents_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "grid.get_neighbors(pos, True, include_center=False, radius={})".format(radius)
method = "get_neighbors"
elapsed_get_neighbors_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "grid.out_of_bounds(pos)"
method = "out_of_bounds"
elapsed_out_of_bounds_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "grid.is_cell_empty(pos)"
method = "is_cell_empty"
elapsed_is_cell_empty_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "grid.move_to_empty(agent)"
method = "move_to_empty"
elapsed_move_to_empty_default = print_elapsed(descr +  method, setup, stmt)
print()

stmt = "for x in grid.iter_cell_list_contents(cell_list): x"
method = "iter_cell_list_contents"
elapsed_iter_cell_list_contents_default = print_elapsed(descr +  method, setup, stmt)
print()


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

descr = "cython memviews "

print("\ntimings with memviews\n")

stmt = "_Grid(width, height, False)"
method = "__init__"
elapsed_init_cython = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_init_default / elapsed_init_cython, 2))

stmt = "grid.get_neighborhood_mview((10, 10), True, include_center=True, radius={})".format(radius)
method = "get_neighborhood_mview"
elapsed_neighborhood_mview_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_neighborhood_default / elapsed_neighborhood_mview_nomap, 2))

stmt = "grid.get_cell_mview_contents(cell_view)"
method = "get_cell_mview_contents"
elapsed_cl_mview_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_cl_default / elapsed_cl_mview_nomap, 2))

stmt = "grid.get_neighbors_mview((10, 10), True, include_center=True, radius={})".format(radius)
method = "get_neighbors_mview"
elapsed_neighbors_mview_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_neighbors_default / elapsed_neighbors_mview_nomap, 2))

stmt = "grid.get_neighborhood((10, 10), True, include_center=True, radius={})".format(radius)
method = "get_neighborhood"
elapsed_neighborhood_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_neighborhood_default / elapsed_neighborhood_nomap, 2))

stmt = "grid.get_cell_list_contents(cell_list)"
method = "get_cell_list_contents"
elapsed_cl_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_cl_default / elapsed_cl_nomap, 2))

stmt = "grid.get_neighbors((10, 10), True, include_center=True, radius={})".format(radius)
method = "get_neighbors"
elapsed_neighbors_nomap = print_elapsed("cython with map get_neighbors", setup.format("_Grid"), stmt)
print(" --> speedup", round(elapsed_neighbors_default / elapsed_neighbors_nomap, 2))

setup = """
import mesa
from space import {0}
import random
random.seed(1)
density = {1}
width = 200
height = 200
grid = {0}(width, height, False)
model = mesa.Model()
for i in range(round(density*width*height)):
    agent = mesa.Agent(i, model)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
pos = (x,y)
cell_list = grid.get_neighborhood(pos, True, include_center=True, radius={2})
""".format("_BaseSingleGrid", density, radius)

descr = "cython grid "

print("\ntimings cython\n")

stmt = "_BaseSingleGrid(width, height, False)"
method = "__init__"
elapsed_init_cython = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_init_default / elapsed_init_cython, 2))

stmt = "grid.get_neighborhood(pos, True, include_center=False, radius={})".format(radius)
method = "get_neighborhood"
elapsed_neighborhood_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_get_neighborhood_default / elapsed_neighborhood_nomap, 2))

stmt = "grid.get_cell_list_contents(cell_list)"
method = "get_cell_list_contents"
elapsed_cl_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_get_cell_list_contents_default / elapsed_cl_nomap, 2))

stmt = "grid.get_neighbors(pos, True, include_center=False, radius={})".format(radius)
method = "get_neighbors"
elapsed_neighbors_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_get_neighbors_default / elapsed_neighbors_nomap, 2))

stmt = "grid.out_of_bounds(pos)"
method = "out_of_bounds"
elapsed_out_of_bounds_cython = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_out_of_bounds_default / elapsed_out_of_bounds_cython, 2))

stmt = "grid.is_cell_empty(pos)"
method = "is_cell_empty"
elapsed_is_cell_empty_cython = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_is_cell_empty_default / elapsed_is_cell_empty_cython, 2))

stmt = "grid.move_to_empty(agent)"
method = "move_to_empty"
elapsed_move_to_empty_cython = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_move_to_empty_default / elapsed_move_to_empty_cython, 2))

stmt = "for x in grid.iter_cell_list_contents(cell_list): x"
method = "iter_cell_list_contents"
elapsed_cl_nomap = print_elapsed(descr +  method, setup, stmt)
print(" --> speedup", round(elapsed_iter_cell_list_contents_default / elapsed_cl_nomap, 2))

