import timeit
from prettytable import PrettyTable

repetition = 1000
radius = 1
density = 0.5

main_setup_single = """
from {0} import SingleGrid
from mesa import Agent, Model
import random
random.seed(1)
density = {1}
width = 100
height = 100
grid = SingleGrid(width, height, True)
model = Model()
for i in range(round(density*width*height)):
    agent = Agent(i, model)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
pos = (x,y)
pos_2 = (-3, -5)
cell_list = grid.get_neighborhood(pos, True, include_center=True, radius={2})
"""

main_setup_multi = """
from {0} import MultiGrid
from mesa import Agent, Model
import random
random.seed(1)
density = {1}
width = 100
height = 100
grid = MultiGrid(width, height, True)
model = Model()
for i in range(round(density*width*height)):
    agent = Agent(i, model)
    x = random.randrange(width)
    y = random.randrange(height)
    grid.place_agent(agent, (x, y))
pos = (x,y)
pos_2 = (-3, -5)
cell_list = grid.get_neighborhood(pos, True, include_center=True, radius={2})
"""

setup_single_python = main_setup_single.format("mesa.space", density, radius)
setup_single_cython = main_setup_single.format("space", density, radius)

setup_multi_python = main_setup_multi.format("mesa.space", density, radius)
setup_multi_cython = main_setup_multi.format("space", density, radius)


dict_method_single_stmt = {
"__init__": "SingleGrid(width, height, False)",
"get_neighborhood": "grid.get_neighborhood(pos, True, include_center=False, radius={})".format(radius),
"get_cell_list_contents": "grid.get_cell_list_contents(cell_list)",
"get_neighbors": "grid.get_neighbors(pos, True, include_center=False, radius={})".format(radius),
"out_of_bounds": "grid.out_of_bounds(pos)",
"is_cell_empty": "grid.out_of_bounds(pos)",
"move_to_empty": "grid.move_to_empty(agent)",
"remove_agent + place_agent": "grid.remove_agent(agent); grid.place_agent(agent, pos)",
"torus_adj": "grid.torus_adj(pos_2)",
"build and call empties": "grid.empties",
"iter_cell_list_contents": "for x in grid.iter_cell_list_contents(cell_list): x",
"iter_neighbors": "for x in grid.iter_neighbors(pos, True, include_center=False, radius={}): x".format(radius),
"coord_iter": "for x in grid.coord_iter(): x",
"__iter__": "for x in grid: x",
"__getitem__ list of tuples": "grid[cell_list]",
"__getitem__ single tuple": "grid[pos]",
"__getitem__ single column": "grid[:, 0]",
"__getitem__ single row": "grid[0, :]",
"__getitem__ grid": "grid[:, :]",
}

dict_method_multi_stmt = dict_method_single_stmt.copy()
dict_method_multi_stmt["__init__"] = "MultiGrid(width, height, False)"

table = PrettyTable()
table.field_names = ["method name", "speed-up singlegrid", "speed-up multigrid"]
table.align = "l"

avg_speed_up = 0

for method in dict_method_single_stmt:
    stmt_single = dict_method_single_stmt[method]
    stmt_multi = dict_method_multi_stmt[method]
    python_time_single = timeit.timeit(stmt_single, setup_single_python, number=repetition)
    cython_time_single = timeit.timeit(stmt_single, setup_single_cython, number=repetition) 
    python_time_multi = timeit.timeit(stmt_multi, setup_multi_python, number=repetition)
    cython_time_multi = timeit.timeit(stmt_multi, setup_multi_cython, number=repetition) 
    micro_python_single = "{:.3f} μs".format(python_time_single * 10**6 / repetition)
    micro_cython_single = "{:.3f} μs".format(cython_time_single * 10**6 / repetition)
    micro_python_multi = "{:.3f} μs".format(python_time_multi * 10**6 / repetition)
    micro_cython_multi = "{:.3f} μs".format(cython_time_multi * 10**6 / repetition)   
    speed_up_single = python_time_single / cython_time_single
    speed_up_multi = python_time_multi / cython_time_multi
    table.add_row([method, "{:.2f}x".format(speed_up_single), "{:.2f}x".format(speed_up_multi)])

print(table)
