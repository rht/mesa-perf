import timeit
from prettytable import PrettyTable

repetition = 1000
radius = 1
density = 0.5

main_setup = """
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

setup_python = main_setup.format("mesa.space", density, radius)
setup_cython = main_setup.format("space", density, radius)

dict_method_stmt = {
"__init__": "SingleGrid(width, height, False)",
"get_neighborhood": "grid.get_neighborhood(pos, True, include_center=False, radius={})".format(radius),
"get_cell_list_contents": "grid.get_cell_list_contents(cell_list)",
"get_neighbors": "grid.get_neighbors(pos, True, include_center=False, radius={})".format(radius),
"out_of_bounds": "grid.out_of_bounds(pos)",
"is_cell_empty": "grid.out_of_bounds(pos)",
"move_to_empty": "grid.move_to_empty(agent)",
"remove_agent": "grid.remove_agent(agent)",
"place_agent": "grid.remove_agent(agent); grid.place_agent(agent, pos)",
"torus_adj": "grid.torus_adj(pos_2)",
"build and call empties": "grid.empties",
"iter_cell_list_contents": "for x in grid.iter_cell_list_contents(cell_list): x",
"iter_neighbors": "for x in grid.iter_neighbors(pos, True, include_center=False, radius={}): x".format(radius),
"coord_iter": "for x in grid.coord_iter(): x",
"__iter__": "for x in grid: x",
}


table = PrettyTable()
table.field_names = ["method singlegrid", "time python", "time cython", "speed-up"]
dict_method_timings = {}

for method, stmt in dict_method_stmt.items():
    python_time = timeit.timeit(stmt, setup_python, number=repetition)
    cython_time = timeit.timeit(stmt, setup_cython, number=repetition) 
    micro_python = "{:.3f} μs".format(python_time * 10**6 / repetition)
    micro_cython = "{:.3f} μs".format(cython_time * 10**6 / repetition)
    speed_up = python_time/ cython_time
    table.add_row([method, micro_python, micro_cython, round(speed_up,2)])

print(table)
