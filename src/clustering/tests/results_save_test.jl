include("../clustering.jl")
using Clustering
using Obj2Dict
using JSON
using Base.Test

results1 = ClusterResults(
  ASCIIString["file1.txt", "file2.txt", "file3.txt"],
  Int64[0, 1, 2],
  3,
  rand(5,5)
  )

d = Obj2Dict.to_dict(results1)
f = open("savetest.json", "w")
JSON.print(f, d)
close(f)

f = open("savetest.json")
dd = JSON.parse(f)
close(f)
results2 = Obj2Dict.to_obj(dd)

@test results1 == results2
