# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable
# law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
# _____________________________________________________________________________
# Reinforcement Learning Encounter Simulator (RLES) includes the following
# third party software. The SISLES.jl package is licensed under the MIT Expat
# License: Copyright (c) 2014: Youngjun Kim.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *****************************************************************************

include("../../defines/define_save.jl")
include("../../helpers/save_helpers.jl")
include("../../visualize/visualize.jl")

using PyCall

@pyimport Levenshtein as pyleven

#String 1 is transformed into String 2

getops(s1::AbstractString, s2::AbstractString) = pyleven.editops(s1, s2)

fields = ["sensor", "ra_detailed", "response", "adm"]

function extract_string_tracked(file::AbstractString)

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

function editops_heatmap(file1::AbstractString, file2::AbstractString;
                         outfile::AbstractString="editops_heatmap.txt")

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
