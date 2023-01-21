import timeit

repetition = 1000


def print_elapsed(label, setup, stmt):
    elapsed = "{:.3f} μs".format(
        timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    )
    print(label, elapsed)


setup = """
import {0}
model = {0}.Model()
schedule = {1}(model{3})
for i in range(200):
    agent = {2}(i, model)
    schedule.add(agent)
"""
stmt = "schedule.step()"
print_elapsed(
    "default", setup.format("mesa", "mesa.time.BaseScheduler", "mesa.Agent", ""), stmt
)
print_elapsed(
    "default shuffled",
    setup.format("mesa", "mesa.time.RandomActivation", "mesa.Agent", ""),
    stmt,
)


# print_elapsed(
#     "numba typed dict",
#     setup.format("numba_version", "numba_version.Scheduler", "numba_version.Agent"),
#     stmt,
# )

print_elapsed(
    "cython python dict",
    "import cython_version\n"
    + setup.format(
        "mesa", "cython_version.SchedulerPythonDict", "mesa.Agent", ", False"
    ),
    stmt,
)
print_elapsed(
    "cython python dict shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa", "cython_version.SchedulerPythonDict", "mesa.Agent", ", True"
    ),
    stmt,
)


print_elapsed(
    "cython python dict, cython agent",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerDictCythonizedAgent",
        "cython_version.Agent",
        ", False",
    ),
    stmt,
)
print_elapsed(
    "cython python dict, cython agent shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerDictCythonizedAgent",
        "cython_version.Agent",
        ", True",
    ),
    stmt,
)


print_elapsed(
    "cython map, cython agent",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerMap",
        "cython_version.Agent",
        ", False",
    ),
    stmt,
)
# print_elapsed(
#     "cython map-dict-cast, cython agent",
#     "import cython_version\n"
#     + setup.format(
#         "mesa",
#         "cython_version.SchedulerMapDictHybrid",
#         "cython_version.Agent",
#         ", False",
#     ),
#     stmt,
# )
