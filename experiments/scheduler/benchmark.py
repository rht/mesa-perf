import timeit

repetition = 1000


def print_elapsed(label, setup, stmt):
    _elapsed = timeit.timeit(stmt, setup, number=repetition) * 10**6 / repetition
    elapsed = "{:.3f} μs".format(_elapsed)
    print(label, elapsed)
    return _elapsed


setup = """
import {0}
model = {0}.Model()
schedule = {1}(model{3})
for i in range(200):
    agent = {2}(i, model)
    schedule.add(agent)
"""
stmt = "schedule.step()"
e_default = print_elapsed(
    "default", setup.format("mesa", "mesa.time.BaseScheduler", "mesa.Agent", ""), stmt
)
e_default_shuffled = print_elapsed(
    "default shuffled",
    setup.format("mesa", "mesa.time.RandomActivation", "mesa.Agent", ""),
    stmt,
)
print()


# print_elapsed(
#     "numba typed dict",
#     setup.format("numba_version", "numba_version.Scheduler", "numba_version.Agent"),
#     stmt,
# )

e_cython = print_elapsed(
    "cython python dict",
    "import cython_version\n"
    + setup.format(
        "mesa", "cython_version.SchedulerPythonDict", "mesa.Agent", ", False, False"
    ),
    stmt,
)
print(" ", round(e_default / e_cython, 2), "x")
e_cython_shuffled = print_elapsed(
    "cython python dict, shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa", "cython_version.SchedulerPythonDict", "mesa.Agent", ", True, False"
    ),
    stmt,
)
print(" ", round(e_default_shuffled / e_cython_shuffled, 2), "x")
print_elapsed(
    "cython python dict, cython shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa", "cython_version.SchedulerPythonDict", "mesa.Agent", ", True, True"
    ),
    stmt,
)
print()


print_elapsed(
    "cython python dict, cython agent",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerDictCythonizedAgent",
        "cython_version.Agent",
        ", False, False",
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
        ", True, False",
    ),
    stmt,
)
print_elapsed(
    "cython python dict, cython agent, cython shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerDictCythonizedAgent",
        "cython_version.Agent",
        ", True, True",
    ),
    stmt,
)

print()


e_cython_fast = print_elapsed(
    "cython map, cython agent",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerMap",
        "cython_version.Agent",
        ", False, False",
    ),
    stmt,
)
print(" ", round(e_default / e_cython_fast, 2), "x")
e_cython_shuffled_fast = print_elapsed(
    "cython map, cython agent shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerMap",
        "cython_version.Agent",
        ", True, False",
    ),
    stmt,
)
e_cython_shuffled_fast = print_elapsed(
    "cython map, cython agent, cython shuffled",
    "import cython_version\n"
    + setup.format(
        "mesa",
        "cython_version.SchedulerMap",
        "cython_version.Agent",
        ", True, True",
    ),
    stmt,
)
print(" ", round(e_default_shuffled / e_cython_shuffled_fast, 2), "x")



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
