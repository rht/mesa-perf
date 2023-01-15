using BenchmarkTools

function get_neighborhood(height::Int, width::Int, pos::Tuple{Int,Int}, moore::Bool, radius::Int)
    x, y = pos
    xfrom = max(0, x - radius)
    xto = min(width, x + radius + 1)
    yfrom = max(0, y - radius)
    yto = min(height, y + radius + 1)

    max_neighborhood_count = (xto - xfrom + 1) * (yto - yfrom + 1)
    neighborhood = Array{Int}(undef, max_neighborhood_count, 2)
    #neighborhood = []

    count = 1
    for nx in xfrom:xto
        for ny in yfrom:yto
            if !moore && (abs(nx - x) + abs(ny - y) > radius)
                continue
            end
            neighborhood[count, 1] = nx
            neighborhood[count, 2] = ny
            #push!(neighborhood, (nx, ny))
            count += 1
        end
    end

    return neighborhood[1:count]
    #return neighborhood
end

function empty()
end

let
    #repetition = 1000
    println("get_neighborhood:")
    #neighborhood = Array{Int}(undef, 30 * 30, 2)
    get_neighborhood(30, 30, (10, 10), true, 10)
    @btime get_neighborhood(30, 30, (10, 10), true, 10)

    println("Empty function:")
    empty()
    @btime empty()
end
