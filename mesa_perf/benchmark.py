import timeit

repetition = 10000

def print_elapsed(label, setup, stmt):
    elapsed = "{:.3f} μs".format(
        timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    )
    print(label, elapsed)

setup = """
import mesa
import random
random.seed(1)
width = 30
height = 30
grid = mesa.space.SingleGrid(width, height, False)
for i in range(10):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius=1)
"""
stmt = "grid._neighborhood_cache = {}; grid.get_neighborhood((10, 10), True, include_center=True, radius=10)"
print_elapsed("python get_neighborhood", setup, stmt)

stmt = "grid.get_cell_list_contents(cell_list)"
print_elapsed("python get_cell_list_contents", setup, stmt)

setup = """
import mesa
import space
import random
random.seed(1)
width = 100
height = 100
grid = space._Grid(width, height, False)
for i in range(10):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius=1)
"""

stmt = "grid.get_neighborhood((10, 10), True, include_center=True, radius=10)"
print_elapsed("cython get_neighborhood", setup, stmt)

stmt = "grid.get_cell_list_contents(cell_list)"
print_elapsed("cython get_cell_list_contents", setup, stmt)
