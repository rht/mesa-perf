import timeit

repetition = 100


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
cell_list = grid.get_neighborhood((10, 10), True, include_center=True, radius=10)
"""
stmt = "grid.get_cell_list_contents(cell_list)"
print_elapsed("default", setup, stmt)


setup = """
import mesa
import cython_grid
import random
random.seed(1)
width = 30
height = 30
grid = cython_grid.{0}(width, height)
for i in range(10):
    agent = mesa.Agent(i, None)
    while True:
        x = random.randrange(width)
        y = random.randrange(height)
        if grid.is_cell_empty((x, y)):
            break
    grid.place_agent(agent, (x, y))
cell_list = grid.get_neighborhood((10, 10), True, 10)
"""
stmt = "grid.get_cell_list_contents(cell_list)"
print_elapsed("cython np.ndarray", setup.format("Grid"), stmt)

print_elapsed("cython list-of-list", setup.format("GridLoL"), stmt)

stmt = "grid.get_cell_list_contents_memoryview(cell_list)"
print_elapsed(
    "cython memoryview-only",
    setup.format("Grid").replace("get_neighborhood", "get_neighborhood_memoryview"),
    stmt,
)

# print_elapsed(
#    "numba np.ndarray",
#    setup.format("Grid").replace("cython_grid", "numba_version"),
#    stmt,
# )
