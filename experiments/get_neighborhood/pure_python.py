def out_of_bounds(pos, width, height) -> bool:
    """Determines whether position is off the grid, returns the out of
    bounds coordinate."""
    x, y = pos
    return x < 0 or x >= width or y < 0 or y >= height


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

    # we use a dict to keep insertion order
    neighborhood = {}

    x, y = pos

    # First we check if the neighborhood is inside the grid
    if (
        x >= radius
        and width - x > radius
        and y >= radius
        and height - y > radius
    ):
        # If the radius is smaller than the distance from the borders, we
        # can skip boundary checks.
        x_range = range(x - radius, x + radius + 1)
        y_range = range(y - radius, y + radius + 1)

        for new_x in x_range:
            for new_y in y_range:
                if not moore and abs(new_x - x) + abs(new_y - y) > radius:
                    continue

                neighborhood[(new_x, new_y)] = True

    else:
        # If the radius is larger than the distance from the borders, we
        # must use a slower method, that takes into account the borders
        # and the torus property.
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                if not moore and abs(dx) + abs(dy) > radius:
                    continue

                new_x = x + dx
                new_y = y + dy

                if torus:
                    new_x %= width
                    new_y %= height

                if not out_of_bounds((new_x, new_y), width, height):
                    neighborhood[(new_x, new_y)] = True

    if not include_center and neighborhood:
        neighborhood.remove(pos)

    # self._neighborhood_cache[cache_key] = neighborhood

    return neighborhood
