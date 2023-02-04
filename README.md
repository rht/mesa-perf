# mesa-perf

These are the speed-up for some parts, which are 100% compatible to Mesa:

Cython MultiGrid in respect to the current one:

```
+----------------------------+-------------+-------------+----------+
| method multigrid           | time python | time cython | speed-up |
+----------------------------+-------------+-------------+----------+
| __init__                   | 1022.150 μs | 310.837 μs  | 3.29x    |
| get_neighborhood           | 0.249 μs    | 0.143 μs    | 1.74x    |
| get_cell_list_contents     | 2.959 μs    | 0.326 μs    | 9.07x    |
| get_neighbors              | 3.185 μs    | 0.385 μs    | 8.27x    |
| out_of_bounds              | 0.175 μs    | 0.040 μs    | 4.32x    |
| is_cell_empty              | 0.174 μs    | 0.040 μs    | 4.32x    |
| move_to_empty              | 5.102 μs    | 1.995 μs    | 2.56x    |
| remove_agent + place_agent | 0.439 μs    | 0.269 μs    | 1.63x    |
| torus_adj                  | 0.269 μs    | 0.070 μs    | 3.83x    |
| build and call empties     | 2.211 μs    | 0.660 μs    | 3.35x    |
| iter_cell_list_contents    | 2.735 μs    | 0.458 μs    | 5.97x    |
| iter_neighbors             | 2.866 μs    | 0.525 μs    | 5.46x    |
| coord_iter                 | 988.736 μs  | 482.695 μs  | 2.05x    |
| __iter__                   | 170.096 μs  | 176.336 μs  | 0.96x    |
| __getitem__ list of tuples | 3.682 μs    | 0.688 μs    | 5.35x    |
| __getitem__ single tuple   | 0.927 μs    | 0.111 μs    | 8.33x    |
| __getitem__ single column  | 4.871 μs    | 2.344 μs    | 2.08x    |
| __getitem__ single row     | 1.272 μs    | 0.394 μs    | 3.22x    |
| __getitem__ grid           | 199.595 μs  | 78.340 μs   | 2.55x    |
+----------------------------+-------------+-------------+----------+
```

Cython SingleGrid in respect to the current one:

```
+----------------------------+-------------+-------------+----------+
| method singlegrid          | time python | time cython | speed-up |
+----------------------------+-------------+-------------+----------+
| __init__                   | 847.527 μs  | 120.952 μs  | 7.01x    |
| get_neighborhood           | 0.273 μs    | 0.145 μs    | 1.88x    |
| get_cell_list_contents     | 2.829 μs    | 0.329 μs    | 8.61x    |
| get_neighbors              | 2.756 μs    | 0.415 μs    | 6.63x    |
| out_of_bounds              | 0.190 μs    | 0.044 μs    | 4.27x    |
| is_cell_empty              | 0.179 μs    | 0.043 μs    | 4.20x    |
| move_to_empty              | 5.957 μs    | 2.152 μs    | 2.77x    |
| remove_agent + place_agent | 0.631 μs    | 0.180 μs    | 3.51x    |
| torus_adj                  | 0.274 μs    | 0.074 μs    | 3.73x    |
| build and call empties     | 2.205 μs    | 0.662 μs    | 3.33x    |
| iter_cell_list_contents    | 2.557 μs    | 0.817 μs    | 3.13x    |
| iter_neighbors             | 2.663 μs    | 0.910 μs    | 2.93x    |
| coord_iter                 | 1004.039 μs | 487.570 μs  | 2.06x    |
| __iter__                   | 228.070 μs  | 184.163 μs  | 1.24x    |
| __getitem__ list of tuples | 3.758 μs    | 0.704 μs    | 5.34x    |
| __getitem__ single tuple   | 0.940 μs    | 0.121 μs    | 7.77x    |
| __getitem__ single column  | 4.825 μs    | 2.354 μs    | 2.05x    |
| __getitem__ single row     | 1.311 μs    | 0.461 μs    | 2.84x    |
| __getitem__ grid           | 199.114 μs  | 82.000 μs   | 2.43x    |
+----------------------------+-------------+-------------+----------+
```
