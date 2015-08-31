include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")
include("../visualize/visualize.jl")

using PyCall

@pyimport Levenshtein as pyleven

#String 1 is transformed into String 2

getops(s1::String, s2::String) = pyleven.editops(s1, s2)

fields = ["sensor", "ra_detailed", "response", "adm"]

function extract_string_tracked(file::String)

  #initialize trackers, k=char position, v=(aircraft id, field)
  tags = Dict{Int64, (Int64, ASCIIString)}()

  d = trajLoad(file)
  buf = IOBuffer()

  for t = 1:50 #FIXME
    for i = 1:sv_num_aircraft(d)
      for field in fields
        size0 = buf.size
        print(buf, sv_simlog_tdata(d, field, i, [t])[1])
        #track
        for pos = size0:buf.size
          tags[pos] = (i, field)
        end
      end
    end
  end

  return takebuf_string(buf), tags
end

function groupby(X::Vector{Any})
  out = Array((Any, Int64), 0)

  for val in unique(X)
    n = count(x -> x == val, X)
    push!(out, (val, n))
  end

  return out
end

function editops_heatmap(file1::String, file2::String)

  s1, tags1 = extract_string_tracked(file1)
  s2, tags2 = extract_string_tracked(file2)

  ops = getops(s1, s2)

  matches1 = IntSet(1:length(s1))
  matches2 = IntSet(1:length(s2))

  for (op, src, dst) in ops
    src += 1 #compensate for 0 indexing
    dst += 1 #compsensate for 0 indexing

    if op == "insert"
      pop!(matches2, dst)
    elseif op == "delete"
      pop!(matches1, src)
    elseif op == "replace"
      pop!(matches1, src)
      pop!(matches2, dst)
    else
      error("op not recognized: $op")
    end
  end

  tagarray1 = map(i -> tags1[i], matches1)
  tagarray2 = map(i -> tags2[i], matches2)
  char_matches1 = groupby(tagarray1)
  char_matches2 = groupby(tagarray2)

  return char_matches1, char_matches2
end
