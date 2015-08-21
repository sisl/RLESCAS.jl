module Clustering

include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")

function extract_string(file::String)
  d = trajLoad(file)
  buf = IOBuffer()


  print(buf, s)

  return buf
end

end #module
