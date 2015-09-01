#Force-directed D3 visualization
#output to JSON

#Format:
#top-level Dict d
#d is Dict{String,Any} has two fields: "nodes" and "links"
#d["nodes"] is an array of Dict{String,Any}
#d["nodes"][1] has two fields "name" and "group"
#d["nodes"][1]["name"] = name of node as a string
#d["nodes"][1]["group"] = group label as an int
#d["links"] is an array of Dict{String,Any}
#d["links"][1] has 3 fields "source", "target", "value"
#d["links"][1]["source"] = index of array of source node (0-indexing)
#d["links"][1]["target"] = index of array of target node (0-indexing)
#d["links"][1]["value"] = force of link

using JSON

function force_directed{T<:String}(names::Vector{T}, labels::Vector{Int},
                                   affinity::Array{Float64,2};
                                       outfile::String="force_directed.json")
    d = Dict{ASCIIString,Any}()
    d["nodes"] = Dict{ASCIIString,Any}[]
    d["links"] = Dict{ASCIIString,Any}[]

    for (name, label) in zip(names, labels)
        node = Dict{ASCIIString,Any}(["name" => name,
                                       "group" => label])
        push!(d["nodes"], node)
    end

    #force function
    F = 1 ./ affinity.^2
    minval, maxval = extrema(filter(x->x!=Inf, F[:])) #min/max excluding 0.0s
    F = 0.01 * ((F - minval) ./ (maxval - minval))
    f(i, j) = F[i, j]

    for i = 1:size(affinity, 1) #rows
        for j = (i + 1):size(affinity, 2) #cols, upper triangular only
            node = Dict{ASCIIString,Any}(["source" => i - 1,
                                          "target" => j - 1,
                                          "value" => f(i, j)])
            push!(d["links"], node)
        end
    end

    f = open(outfile, "w")
    JSON.print(f, d)
    close(f)

    d
end
