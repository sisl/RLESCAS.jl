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

include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")

function calc_catranges(catlengths::Vector{Int64})
  cl = [1; cumsum(catlengths) + 1]
  return Range[cl[i]:(cl[i+1] - 1) for i = 1:length(catlengths)]
end

function json_to_csv{T<:AbstractString}(savefile::AbstractString,
                                categories::Vector{T} = ["command", "sensor", "ra", "ra_detailed", "response",
                                                       "adm", "wm"])

  d = trajLoad(savefile)

  catlengths = Int64[length(sv_simlog_names(d, c)) for c in categories]
  catranges = calc_catranges(catlengths)
  t_end = maximum([length(sorted_times(d, c, 1)) for c in categories])
  num_aircraft = sv_num_aircraft(d)

  header = convert(Array{ASCIIString}, vcat([map(s->"$c.$s", sv_simlog_names(d, c)) for c = categories]...))
  units = convert(Array{ASCIIString}, vcat([map(u->"$u", sv_simlog_units(d, c)) for c = categories]...))
  data = Array(Any, t_end, length(header), num_aircraft)
  fill!(data, "n/a")

  for i = 1 : num_aircraft
    for (j, c) = enumerate(categories)
      for t = sorted_times(d, c, i)
        data[t, catranges[j], i] = sv_simlog_tdata(d, c, i, [t])[1]
      end
    end

    fileroot = getSaveFileRoot(savefile)
    filename = string(fileroot, "_aircraft$i.csv")
    f = open(filename, "w")
    writecsv(f, header')
    writecsv(f, units')
    writecsv(f, data[:, :, i])
    close(f)
  end

  return header, units, data
end
