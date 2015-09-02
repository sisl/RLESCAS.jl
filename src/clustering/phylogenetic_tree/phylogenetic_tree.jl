module PhylogeneticTree

export vis_from_tree, vis_from_distances

using TikzPictures

type PhylotreeElement
  level::Int64
  name::ASCIIString
  children::Vector{PhylotreeElement}
end

PhylotreeElement(level::Int64, name::String="") = PhylotreeElement(level, name, PhylotreeElement[])
PhylotreeElement(level::Int64, name::String, children::PhylotreeElement...) =
  PhylotreeElement(level, name, [children...])

#assume a scikit-learn agglomerative clustering output tree format and 0-indexing
function vis_from_tree(nelements::Int64, tree0::Array{Int32,2};
                           nametable::Dict{Int64,ASCIIString}=Dict{Int64,ASCIIString}(),
                           show_intermediate::Bool=true,
                           outfileroot::String="cluster_tree",
                           output::String="TEXPDF")

  lastid = nelements - 1
  root_id = lastid #id of the root node, init value

  d = Dict{Int64, PhylotreeElement}()

  #preload dict with level 0's
  for i = 0:lastid
    name = haskey(nametable, i) ? nametable[i] : "$i"
    d[i] = PhylotreeElement(0, name)
  end

  #parse tree into dict
  for row = 1:size(tree0, 1)
    root_id += 1
    (i, j) = tree0[row, :]
    level = max(d[i].level, d[j].level) + 1
    name = show_intermediate ? "$(root_id)" : ""
    d[root_id] = PhylotreeElement(level, name, d[i], d[j])
  end

  #create tikz text
  io = IOBuffer()
  print(io, "{")
  print_element!(io, d[root_id])
  print(io, "};")

  return takebuf_string(io)
end

function print_element!(io::IOBuffer, element::PhylotreeElement, parent_level::Int64=-1)

  len = parent_level - element.level

  print(io, "$(element.name)")
  if len > 0
    print(io, "[>length=$len]")
  end

  #process children
  if !isempty(element.children)
    print(io, " -- {")
    for child in element.children
      print_element!(io, child, element.level)
      print(io, ",")
    end
    seek(io, position(io) - 1) #backspace to remove trailing comma
    print(io, "}")
  end
end

function vis_from_distances(affinity::Array{Float64,2}, offset_scale::Float64=0.8;
                            nametable::Vector{ASCIIString}=ASCIIString[],
                           outfileroot::String="cluster_tree",
                           output::String="TEXPDF")


  preamble = string("\\usetikzlibrary{graphs, graphdrawing}\n",
                    "\\usegdlibrary{phylogenetics}\n",
                    "\\pgfgdset{phylogenetic inner node/.style={
/tikz/.cd, draw, circle, inner sep=0pt, minimum size=5pt
}}",
                    "\\pgfgdset{phylogenetic edge/.style={
/tikz/.cd, thick, rounded corners
}}")
  io = IOBuffer()
  print(io, "\\graph [phylogenetic tree layout, upgma, distance matrix={")
  minval, maxval = extrema(affinity[find(affinity)])
  offset = offset_scale * minval
  diagmat = diagm(offset * ones(size(affinity, 1)))
  print_matrix!(io, affinity - offset + diagmat, 30 / maxval)
  println(io, "}]")
  print(io, "{")
  print_names!(io, nametable, size(affinity, 1))
  print(io, "};")

  tp = TikzPicture(takebuf_string(io), preamble=preamble)
  if output == "TEXPDF"
    save(PDF(outfileroot), tp)
    save(TEX(outfileroot), tp)
  elseif output == "PDF"
    save(PDF(outfileroot), tp)
  elseif output == "TEX"
    save(TEX(outfileroot), tp)
  else
    error("Unrecognized output type")
  end

  tp
end

function print_matrix!(io::IOBuffer, X::Array{Float64, 2}, scale::Float64=1.0)
  nrows, ncols = size(X)
  for i = 1:nrows
    for j = 1:ncols
      print(io, scale * X[i, j], " ")
    end
    print(io, "\n")
  end
end

function print_names!(io::IOBuffer, nametable::Vector{ASCIIString}, n::Int64)

  for i = 1:n
    name = !isempty(nametable) ? nametable[i] : i
    print(io, name, ",")
  end
  seek(io, position(io) - 1) #backspace, erase extra comma
  nothing
end

end #module

#=
nametable=[13,19,27,29,39,4,45,50,55,61,64,7,72,73,84,9,97,99]
nametable=map(x->string("enc$x"),nametable)
=#
