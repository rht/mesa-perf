from cpython cimport array
import array


cpdef object compute_neighborhood_array(
    object pos,
    bint moore,
    int radius,
    int width,
    int height,
):

    cdef array.array neighborhood_x = array.array("i", [])
    cdef array.array neighborhood_y = array.array("i", [])
    #neighborhood_x = cython.declare(array.array, array.array("i", []))
    #neighborhood_y = cython.declare(array.array, array.array("i", []))

    cdef int x, y
    x, y = pos

    cdef int min_x_range, max_x_range
    cdef int min_y_range, max_y_range
    min_x_range = max(0, x - radius)
    max_x_range = min(width, x + radius + 1)
    min_y_range = max(0, y - radius)
    max_y_range = min(height, y + radius + 1)

    cdef int nx, ny
    cdef array.array tnx, tny
    for nx in range(min_x_range, max_x_range):
        for ny in range(min_y_range, max_y_range):

            if not moore and abs(nx - x) + abs(ny - y) > radius:
                continue

            neighborhood_x.append(nx)
            neighborhood_y.append(ny)
            #tnx = array.array("i", [nx])
            #tny = array.array("i", [ny])
            #array.extend(neighborhood_x, tnx)
            #array.extend(neighborhood_y, tny)

    return neighborhood_x, neighborhood_y
