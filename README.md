# mesa-perf

Project to speed-up different parts of Mesa.

We have two plans we want to carry out:

- Make some faster drop-in replacement components to be used in Mesa Repo as substitute to the current components without affecting the user experience anyhow;
- Create some very fast version of components to be used mostly from Cython, so that the user could use this version to improve even more the speed of the simulation if needed.

Currently, we implemented drop-in replacement SingleGrid and MultiGrid components using Cython.

These are the speed-ups for some methods:

```
+----------------------------+---------------------+--------------------+
| method name                | speed-up singlegrid | speed-up multigrid |
+----------------------------+---------------------+--------------------+
| __init__                   | 9.26x               | 3.62x              |
| get_neighborhood           | 1.51x               | 1.55x              |
| get_cell_list_contents     | 10.63x              | 11.55x             |
| get_neighbors              | 6.98x               | 7.89x              |
| out_of_bounds              | 4.20x               | 3.97x              |
| is_cell_empty              | 3.84x               | 4.11x              |
| move_to_empty              | 2.84x               | 2.60x              |
| remove_agent + place_agent | 3.87x               | 1.81x              |
| torus_adj                  | 4.11x               | 3.85x              |
| build and call empties     | 2.84x               | 3.05x              |
| iter_cell_list_contents    | 3.38x               | 6.95x              |
| iter_neighbors             | 2.87x               | 5.52x              |
| coord_iter                 | 1.58x               | 1.62x              |
| __iter__                   | 1.01x               | 1.01x              |
| __getitem__ list of tuples | 5.49x               | 5.15x              |
| __getitem__ single tuple   | 8.41x               | 8.27x              |
| __getitem__ single column  | 2.55x               | 2.49x              |
| __getitem__ single row     | 2.64x               | 3.15x              |
| __getitem__ grid           | 2.46x               | 2.57x              |
+----------------------------+---------------------+--------------------+
```

We also used these grids instead of the ones present in the Mesa repository for some simulations in the [mesa-examples](https://github.com/projectmesa/mesa-examples/tree/main/examples) repository: we calculated an overall 2.5x speed-up for the `schelling` model and an overall 2x speed-up for the more realistic example `sugarscape_g1mt` one.
