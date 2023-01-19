import cython


def compute_neighborhood(
    pos: (cython.int, cython.int),
    moore: cython.bint,
    include_center: cython.bint,
    radius: cython.int,
    torus: cython.bint,
    width: cython.int,
    height: cython.int,
) -> list:

    neighborhood: list = [0] * (width * height)

    x: cython.int
    y: cython.int
    x, y = pos
    n_pos: (cython.int, cython.int)
    count: cython.int = 0
    if torus:
        x_max_radius, y_max_radius = width // 2, height // 2

        x_radius: cython.int
        y_radius: cython.int
        x_radius, y_radius = min(radius, x_max_radius), min(radius, y_max_radius)

        xdim_even, ydim_even = (width + 1) % 2, (height + 1) % 2
        kx: cython.int = 1 if x_radius == x_max_radius and xdim_even else 0
        ky: cython.int = 1 if y_radius == y_max_radius and ydim_even else 0

        dx: cython.int
        dy: cython.int
        for dx in range(-x_radius, x_radius + 1 - kx):
            for dy in range(-y_radius, y_radius + 1 - ky):

                if not moore and abs(dx) + abs(dy) > radius:
                    continue

                n_pos = (x + dx) % width, (y + dy) % height
                neighborhood[count] = n_pos
                count += 1
    else:
        min_x_range: cython.int = max(0, x - radius)
        max_x_range: cython.int = min(width, x + radius + 1)
        min_y_range: cython.int = max(0, y - radius)
        max_y_range: cython.int = min(height, y + radius + 1)

        nx: cython.int
        ny: cython.int
        for nx in range(min_x_range, max_x_range):
            for ny in range(min_y_range, max_y_range):

                if not moore and abs(nx - x) + abs(ny - y) > radius:
                    continue

                n_pos = (nx, ny)
                neighborhood[count] = n_pos
                count += 1

    if not include_center:
        neighborhood.remove(pos)

    return neighborhood[:count]
