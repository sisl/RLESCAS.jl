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

export feature_matrix

using RLESUtils.LookupCallbacks
using DataFrames

function feature_matrix{T<:String}(csvfiles::Vector{T}, feature_map::Vector{LookupCallback})
  f(csvfile::String) = feature_matrix(csvfile, feature_map)
  return vcat(f, csvfiles)
end

function feature_matrix(csvfiles::Vector{ASCIIString}, feature_map::Vector{LookupCallback},
                        colnames::Vector{ASCIIString}=ASCIIString[])
  #files = one aircraft per csv file
  #lookup the variables in lookups and pass them to the function in mapper
  #e.g., lookups[1] = ["wm.x", "wm.y"], values x and y are retrieved from file,
  # then z = mapper[1](x, y) is written to the vector
  #num_features (rows) x num_timesteps (cols)
  csv = readcsv(csvfile)
  headers = csv[1, :] |> vec
  units = csv[2, :] |> vec
  dat = csv[3:end, :]
  tmax = size(dat, 1)
  V = Array(Float64, length(feature_map))

  lookup_ids = map(feature_map) do lcb
    ids = map(lcb.lookups) do l
      findfirst(x -> x == l, headers)
    end
    any(x -> x == 0, ids) && error("Lookup not found: $v") #all lookup ids should be found
    return ids
  end
  for t = 1:tmax, i = 1:size(M, 1)
    input_vars = dat[t, lookup_ids[i]]
    f = feature_map[i].callback
    M[i, t] = f(input_vars...) |> float64
  end
  return M
end

end #module
