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
schedule = {1}(model)
for i in range(200):
    agent = {2}(i, model)
    schedule.add(agent)
"""
stmt = "schedule.step()"
print_elapsed(
    "default", setup.format("mesa", "mesa.time.RandomActivation", "mesa.Agent"), stmt
)

print_elapsed(
    "numba typed dict",
    setup.format("numba_version", "numba_version.Scheduler", "numba_version.Agent"),
    stmt,
)

print_elapsed(
    "cython python dict",
    "import cython_version\n"
    + setup.format("mesa", "cython_version.SchedulerPythonDict", "mesa.Agent"),
    stmt,
)
print_elapsed(
    "cython python dict, cython agent",
    "import cython_version\n"
    + setup.format(
        "mesa", "cython_version.SchedulerPythonDict", "cython_version.Agent"
    ),
    stmt,
)
