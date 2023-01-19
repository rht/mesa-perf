def get_neighborhood(pos, moore, include_center, radius, torus, width, height):
    """Return a list of cells that are in the neighborhood of a
    certain point.
    Args:
        pos: Coordinate tuple for the neighborhood to get.
        moore: If True, return Moore neighborhood
               (including diagonals)
               If False, return Von Neumann neighborhood
               (exclude diagonals)
        include_center: If True, return the (x, y) cell as well.
                        Otherwise, return surrounding cells only.
        radius: radius, in cells, of neighborhood to get.
    Returns:
        A list of coordinate tuples representing the neighborhood;
        With radius 1, at most 9 if Moore, 5 if Von Neumann (8 and 4
        if not including the center).
    """
    # cache_key = (pos, moore, include_center, radius)

    # neighborhood = self._neighborhood_cache.get(cache_key, None)

    # if neighborhood is not None:
    #    return neighborhood

    # We use a list instead of a dict for the neighborhood because it would
    # be easier to port the code to Cython or Numba (for performance
    # purpose), with minimal changes. To better understand how the
    # algorithm was conceived, look at
    # https://github.com/projectmesa/mesa/pull/1476#issuecomment-1306220403
    # and the discussion in that PR in general.
    neighborhood = []

    x, y = pos
    if torus:
        x_max_radius, y_max_radius = self.width // 2, self.height // 2
        x_radius, y_radius = min(radius, x_max_radius), min(radius, y_max_radius)

        # For each dimension, in the edge case where the radius is as big as
        # possible and the dimension is even, we need to shrink by one the range
        # of values, to avoid duplicates in neighborhood. For example, if
        # the width is 4, while x, x_radius, and x_max_radius are 2, then
        # (x + dx) has a value from 0 to 4 (inclusive), but this means that
        # the 0 position is repeated since 0 % 4 and 4 % 4 are both 0.
        xdim_even, ydim_even = (self.width + 1) % 2, (self.height + 1) % 2
        kx = int(x_radius == x_max_radius and xdim_even)
        ky = int(y_radius == y_max_radius and ydim_even)

        for dx in range(-x_radius, x_radius + 1 - kx):
            for dy in range(-y_radius, y_radius + 1 - ky):

                if not moore and abs(dx) + abs(dy) > radius:
                    continue

                nx, ny = (x + dx) % width, (y + dy) % height
                neighborhood.append((nx, ny))
    else:
        x_range = range(max(0, x - radius), min(width, x + radius + 1))
        y_range = range(max(0, y - radius), min(height, y + radius + 1))

        for nx in x_range:
            for ny in y_range:

                if not moore and abs(nx - x) + abs(ny - y) > radius:
                    continue

                neighborhood.append((nx, ny))

    if not include_center and neighborhood:
        neighborhood.remove(pos)

    # self._neighborhood_cache[cache_key] = neighborhood

    return neighborhood
