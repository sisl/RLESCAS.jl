module Clustering

export ClusterResults, cluster, cluster_vis

include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")
include("../visualize/visualize.jl")

using PyCall
using Levenshtein
using CPUTime
using TikzPictures
using PGFPlots

@pyimport sklearn.cluster as skcluster

type ClusterResults
  files::Vector{ASCIIString}
  labels::Vector{Int64}
  n_clusters::Int64
  affinity::Array{Float64,2}
end

ClusterResults() = ClusterResults(ASCIIString[], Int64[], -1, Array(Float64, 0, 0))

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

function cluster(files::Vector{String}, n_clusters::Int)

  CPUtic()
  X = map(extract_string, files)
  println("Extract string: $(CPUtoq()) seconds")

  #compute affinity matrix
  CPUtic()
  A = [levenshtein(X[i], X[j]) for i = 1:length(X), j = 1:length(X)]
  println("Compute affinity matrix: $(CPUtoq()) seconds")

  #returns a PyObject
  model = skcluster.AgglomerativeClustering(n_clusters=n_clusters, affinity="precomputed", linkage="average")

  CPUtic()
  model[:fit](A)
  println("Sklearn clustering: $(CPUtoq()) seconds")

  labels = model[:labels_]

  return ClusterResults(files, labels, n_clusters, A)
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

end #module
