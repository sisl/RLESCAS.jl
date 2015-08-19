#requires python and scikit-learn
using PyCall
using Levenshtein

@pyimport sklearn.cluster as skcluster

roots = ["aaaa", "bbbb", "cccc", "dddd"]
n_members = 10
data = Array(ASCIIString, length(roots), n_members)

for (i, r) in enumerate(roots)
  data[i, :] = [string(r, j-1) for j = 1:n_members]
end

data[:] = shuffle(data[:])

#returns a PyObject
model = skcluster.AgglomerativeClustering(n_clusters=length(roots), affinity="precomputed", linkage="average")

#compute affinity matrix
A = [levenshtein(data[i], data[j]) for i = 1:length(data), j = 1:length(data)]

model[:fit](A)

labels = model[:labels_]

clusters = Array(Array{ASCIIString},0)

for l in unique(labels)
  push!(clusters, data[find(x -> x == l, labels)])
end

@show data[:]

for c in clusters
  println(c)
end
