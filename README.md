# mesa-perf

Project to speed-up different parts of Mesa.

We have two plans we want to carry out:

- A Cython backend with a Python API making some faster drop-in replacement components to be used in Mesa Repo as substitute to the current components without affecting the user experience anyhow;
- A Cython backend with a Cython API so that to create some very fast version of components to be used (mostly) from Cython, so that the user could use this version to improve even more the speed of the simulation if needed.

Currently, we implemented drop-in replacement SingleGrid and MultiGrid components using Cython. We didn't make a lot of use of MemoryViews since having a Python API would have required to convert back and forth between MemoryViews and Python objects, causing some major slowdowns in some cases.

These are the speed-ups for some methods in common situations:

```
+----------------------------+---------------------+--------------------+
| method name                | speed-up singlegrid | speed-up multigrid |
+----------------------------+---------------------+--------------------+
| __init__                   | 8.97x               | 3.46x              |
| get_neighborhood           | 1.62x               | 1.55x              |
| get_cell_list_contents     | 11.23x              | 11.86x             |
| get_neighbors              | 6.96x               | 8.00x              |
| out_of_bounds              | 4.05x               | 3.88x              |
| is_cell_empty              | 3.96x               | 3.81x              |
| move_to_empty              | 2.88x               | 2.57x              |
| remove_agent + place_agent | 3.82x               | 1.71x              |
| torus_adj                  | 4.35x               | 3.80x              |
| build and call empties     | 2.82x               | 3.01x              |
| iter_cell_list_contents    | 3.41x               | 6.87x              |
| iter_neighbors             | 2.85x               | 5.41x              |
| coord_iter                 | 1.61x               | 1.62x              |
| __iter__                   | 0.98x               | 1.00x              |
| __getitem__ list of tuples | 5.70x               | 5.08x              |
| __getitem__ single tuple   | 8.90x               | 8.29x              |
| __getitem__ single column  | 2.51x               | 2.38x              |
| __getitem__ single row     | 2.64x               | 3.08x              |
| __getitem__ grid           | 2.33x               | 2.61x              |
+----------------------------+---------------------+--------------------+
```

We also used these grids instead of the ones present in the Mesa repository for some simulations in the [mesa-examples](https://github.com/projectmesa/mesa-examples/tree/main/examples) repository: we calculated an overall 2.5x speed-up for the `schelling` model and an overall 2x speed-up for the more realistic `sugarscape_g1mt` model.
