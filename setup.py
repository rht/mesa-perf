from setuptools import setup
from Cython.Build import cythonize

setup(
    name="Mesa-Perf",
    ext_modules=cythonize("mesa_perf/*.pyx"),
)
