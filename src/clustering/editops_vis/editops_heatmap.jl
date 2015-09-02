include("../../defines/define_save.jl")
include("../../helpers/save_helpers.jl")
include("../../visualize/visualize.jl")

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

#group by value of occurrences, i.e., produce a histogram
function groupby(X::Vector{Any})
  out = Array((Any, Int64), 0)

  for val in unique(X)
    n = count(x -> x == val, X)
    push!(out, (val, n))
  end

  return out
end

function editops_heatmap(file1::String, file2::String;
                         outfile::String="editops_heatmap.txt")

  s1, tags1 = extract_string_tracked(file1)
  s2, tags2 = extract_string_tracked(file2)

  ops = getops(s1, s2)

  edits = Any[]
  totals = Any[]

  for (op, src, dst) in ops
    src += 1 #compensate for 0 indexing
    dst += 1 #compsensate for 0 indexing

    if op == "insert"
      push!(edits, tags2[dst])
    elseif op == "delete"
      push!(edits, tags1[src])
    elseif op == "replace"
      push!(edits, tags1[src])
    else
      error("op not recognized: $op")
    end
  end

  for i = 1:length(s1)
    push!(totals, tags1[i])
  end

  edit_stats = groupby(edits)
  total_stats = groupby(totals)

  fraction = Any[]
  for (edit_record, total_record) in zip(edit_stats, total_stats)

    @assert edit_record[1] == total_record[1] # == val

    val, edit_count = edit_record
    val, total_count = total_record
    push!(fraction, (val, edit_count / total_count))
  end

  f = open(outfile, "w")
  println(f, "EDIT_STATS")
  for i = 1:size(edit_stats, 1)
    println(f, edit_stats[i])
  end
  println(f, "\n\nTOTAL_STATS")
  for i = 1:size(edit_stats, 1)
    println(f, total_stats[i])
  end
  println(f, "\n\nFRACTION")
  for i = 1:size(edit_stats, 1)
    println(f, fraction[i])
  end
  close(f)

  return edit_stats, total_stats, fraction
end
