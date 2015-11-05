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

module CSVFeatures

export feature_frame, csv_to_dataframe

using RLESUtils.LookupCallbacks
using RLESUtils.FileUtils
using DataFrames
using Iterators

function feature_frame(csvfile::ASCIIString, feature_map::Vector{LookupCallback},
                        colnames::Vector{Symbol}=Symbol[])

  csv = readcsv(csvfile)
  headers = csv[1, :] |> vec
  units = csv[2, :] |> vec
  dat = csv[3:end, :]
  tmax = size(dat, 1)
  V = Array(Any, length(feature_map))

  lookup_ids = map(feature_map) do lcb
    ids = map(lcb.lookups) do l
      findfirst(x -> x == l, headers)
    end
    any(x -> x == 0, ids) && error("Lookup not found: $lcb") #all lookup ids should be found
    return ids
  end
  for i = 1:length(V)
    input_vars = dat[:, lookup_ids[i]]
    f = feature_map[i].callback
    V[i] = mapslices(x -> f(x...), input_vars, 2) |> vec
  end
  return DataFrame(V, colnames)
end

append(V::Vector{ASCIIString}, s::String) = map(x -> "$(x)$(s)", V)

#map a directory of trajSave_aircraft.csv files to trajSave_dataframe.csv file
function csv_to_dataframe(files::Vector{ASCIIString}, feature_map::Vector{LookupCallback}, feature_names::Vector{ASCIIString}; outdir::ASCIIString="./")
  @assert length(feature_map) == length(feature_names)
  sort!(files)
  grouped_files = Iterators.groupby(x -> split(x, "_aircraft")[1], files) |> collect
  outfiles = Array(ASCIIString, length(grouped_files))
  for i = 1:length(grouped_files)
    D_ = map(enumerate(grouped_files[i])) do jf
      (j, f) = jf
      feature_frame(f, feature_map, convert(Vector{Symbol}, append(feature_names, "_$j")))
    end
    D = hcat(D_...)
    df_file = split(grouped_files[i][1], "_aircraft")[1] * "_dataframe.csv"
    df_file = joinpath(outdir, basename(df_file))
    outfiles[i] = df_file
    writetable(df_file, D)
  end
  return outfiles
end

end #module
