import numpy as np
import numba as nb
from numba import types

locals = {
    "x": types.int64,
    "y": types.int64,
    "xfrom": types.int64,
    "xto": types.int64,
    "yfrom": types.int64,
    "yto": types.int64,
    "count": types.int64,
}
# @nb.njit(nb.int64[:, :](nb.int64, nb.int64, nb.int64[:], nb.boolean, nb.int64), cache=True, locals=locals)
@nb.njit(cache=True, locals=locals)
def get_neighborhood(height, width, pos, moore, radius):
    x, y = pos
    xfrom = max(0, x - radius)
    xto = min(width, x + radius + 1)
    yfrom = max(0, y - radius)
    yto = min(height, y + radius + 1)

    max_neighborhood_count = (xto - xfrom) * (yto - yfrom)
    neighborhood = np.empty((max_neighborhood_count, 2), np.int64)

    count = 0
    for nx in range(xfrom, xto):
        for ny in range(yfrom, yto):
            if not moore and abs(nx - x) + abs(ny - y) > radius:
                continue
            neighborhood[count, 0] = nx
            neighborhood[count, 1] = ny
            count += 1

    return neighborhood[:count]
