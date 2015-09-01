module Clustering

export ClusterResults, cluster, cluster_vis, save_results, load_results, extract_string, hamming, get_affinity

include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")
include("../visualize/visualize.jl")

using PyCall
using Levenshtein
using TikzPictures
using PGFPlots
using Obj2Dict
using JSON

@pyimport sklearn.cluster as skcluster

type ClusterResults
  files::Vector{ASCIIString}
  labels::Vector{Int64}
  tree::Array{Int32, 2}
  n_clusters::Int64
  affinity::Array{Float64, 2}
end

ClusterResults() = ClusterResults(ASCIIString[], Int64[], Array(Int32, 0, 0),
                                  -1, Array(Float64, 0, 0))

function ==(x1::ClusterResults, x2::ClusterResults)

  for sym in names(ClusterResults)
    if x1.(sym) != x2.(sym)
      return false #any field that doesn't match, return false
    end
  end

  return true #all fields must match to return true
end

fields = ["sensor", "ra_detailed", "response", "adm"]

function extract_string(file::String)
  d = trajLoad(file)
  buf = IOBuffer()

  for t = 1:50 #FIXME
    for i = 1:sv_num_aircraft(d)
      for field in fields
        print(buf, sv_simlog_tdata(d, field, i, [t])[1])
      end
    end
  end

  return takebuf_string(buf)
end

function cluster{T<:String}(files::Vector{T}, n_clusters::Int,
                 get_affinity::Function=x->get_affinity(x, levenshtein))

  tic() #CPUtime doesn't work well for parallel
  X = pmap(extract_string, files)
  X = convert(Vector{ASCIIString}, X)
  println("Extract string: $(toq()) wall seconds")

  #compute affinity matrix
  tic()
  A = get_affinity(X)
  println("Compute affinity matrix: $(toq()) wall seconds")

  #returns a PyObject
  model = skcluster.AgglomerativeClustering(n_clusters=n_clusters,
                                            affinity="precomputed",
                                            linkage="average")

  tic()
  model[:fit](A)
  println("Sklearn clustering: $(toq()) wall seconds")

  labels = model[:labels_]
  tree = model[:children_]

  return ClusterResults(files, labels, tree, n_clusters, A)
end

function cluster_vis(results::ClusterResults; outfileroot::String="clustervis")

  labelset = unique(results.labels)

  for label in labelset
    td = TikzDocument()

    for (f, l) in filter(x -> x[2] == label, zip(results.files, results.labels))
      d = trajLoad(f)
      tps = pgfplotLog(d)
      cap = string(vis_runtype_caps(d, sv_run_type(d)),
                   vis_sim_caps(d),
                   vis_runinfo_caps(d))
      add_to_document!(td, tps, cap)
    end

    outfile = string(outfileroot, "_$(label).pdf")
    TikzPictures.save(PDF(outfile), td)
    outfile = string(outfileroot, "_$(label).tex")
    TikzPictures.save(TEX(outfile), td)
  end

end

function get_affinity{T<:String}(X::Vector{T}, get_distance::Function)

  indmatrix = [(i, j) for i = 1:length(X), j = 1:length(X)]

  #compute for upper triangular
  #diag and lower triangular are zero
  A = pmap(ij -> begin
              i, j = ij
              i < j ? get_distance(X[i], X[j]) : 0.0
           end,
           indmatrix)

  A = reshape(A, length(X), length(X))

  #copy lower triangular from upper
  for i = 1:length(X)
    for j = 1:(i-1)
      A[i, j] = A[j, i]
    end
  end

  return convert(Array{Float64, 2}, A)
end

function hamming(s1::String, s2::String)
  x = collect(s1)
  y = collect(s2)

  #pad to common length
  if length(x) < length(y)
    x = vcat(x, fill('-', (length(y) - length(x)))) #pad x
  elseif length(y) < length(x)
    y = vcat(y, fill('-', (length(x) - length(y)))) #pad y
  end

  return sum(x .!= y)
end

function save_results(results::ClusterResults, outfile::String="cluster_results.json")
  f = open(outfile, "w")
  d = Obj2Dict.to_dict(results)
  JSON.print(f, d)
  close(f)

  return outfile
end

function load_results(file::String="cluster_results.json")
  f = open(file)
  d = JSON.parse(f)
  close(f)

  return Obj2Dict.to_obj(d)
end

type PhylotreeElement
  level::Int64
  name::ASCIIString
  children::Vector{PhylotreeElement}
end

PhylotreeElement(level::Int64, name::String="") = PhylotreeElement(level, name, PhylotreeElement[])
PhylotreeElement(level::Int64, name::String, children::PhylotreeElement...) =
  PhylotreeElement(level, name, [children...])

function phylogenetic_tree(results::ClusterResults)
end

#assume a scikit-learn agglomerative clustering output tree format and 0-indexing
function phylogenetic_tree(nelements::Int64, tree0::Array{Int32,2};
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

end #module
