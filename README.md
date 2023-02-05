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
| __init__                   | 9.36x               | 3.62x              |
| get_neighborhood           | 1.70x               | 1.63x              |
| get_cell_list_contents     | 10.23x              | 11.36x             |
| get_neighbors              | 6.76x               | 8.54x              |
| out_of_bounds              | 4.12x               | 3.88x              |
| is_cell_empty              | 4.08x               | 3.77x              |
| move_to_empty              | 2.76x               | 2.75x              |
| remove_agent + place_agent | 3.44x               | 1.89x              |
| torus_adj                  | 3.58x               | 3.59x              |
| build and call empties     | 2.80x               | 3.24x              |
| iter_cell_list_contents    | 3.43x               | 7.01x              |
| iter_neighbors             | 2.87x               | 5.14x              |
| coord_iter                 | 1.65x               | 1.60x              |
| __iter__                   | 0.99x               | 1.01x              |
| __getitem__ list of tuples | 5.85x               | 5.03x              |
| __getitem__ single tuple   | 17.04x              | 17.73x             |
| __getitem__ single column  | 2.79x               | 2.52x              |
| __getitem__ single row     | 3.03x               | 3.99x              |
| __getitem__ grid           | 2.49x               | 3.03x              |
+----------------------------+---------------------+--------------------+
```

We also used these grids instead of the ones present in the Mesa repository for some simulations in the [mesa-examples](https://github.com/projectmesa/mesa-examples/tree/main/examples) repository: we calculated an overall 2.5x speed-up for the `schelling` model and an overall 2x speed-up for the more realistic `sugarscape_g1mt` model.
