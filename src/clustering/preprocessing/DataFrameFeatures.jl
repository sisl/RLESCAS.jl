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

module DataFrameFeatures

export add_features!, transform!

using DataFrames
using Iterators
using RLESUtils: FileUtils, LookupCallbacks

function add_features!(df_files::Vector{ASCIIString}, feature_map::Vector{LookupCallback},
                        feature_names::Vector{ASCIIString}; overwrite::Bool=false)
  map(df_files) do f
    add_features!(f, feature_map, feature_names; overwrite=overwrite)
  end
end

function add_features!(df_file::AbstractString, feature_map::Vector{LookupCallback},
                        feature_names::Vector{ASCIIString}; overwrite::Bool=false)
  D = readtable(df_file)
  add_features!(D, feature_map, feature_names)
  fileroot, ext = splitext(df_file)
  f = overwrite ? df_file : fileroot * "_addfeats" * ext
  writetable(f, D)
  return f
end

function add_features!(Ds::Vector{DataFrame}, feature_map::Vector{LookupCallback},
                        feature_names::Vector{ASCIIString})
  map(Ds) do D
    add_features!(D, feature_map, feature_names)
  end
end

function add_features!(D::DataFrame, feature_map::Vector{LookupCallback},
                        feature_names::Vector{ASCIIString})
  for i = 1:length(feature_map)
    lookups = map(symbol, feature_map[i].lookups) #map lookups to symbols
    f = feature_map[i].callback #function
    feat_name = symbol(feature_names[i]) #as a symbol
    D[feat_name] = Array(Any, size(D, 1)) #add a new column
    for r = 1:size(D, 1)
      x = map(l -> D[r, l], lookups) #extract to a vector
      D[r, feat_name] = f(x...)
    end
  end
  return D
end

function transform!(df_files::Vector{ASCIIString}, feat_transforms::Tuple{Symbol,Function}...; overwrite::Bool=false)
  map(df_files) do f
    transform!(f, feat_transforms..., overwrite=overwrite)
  end
end

function transform!(df_file::AbstractString, feat_transforms::Tuple{Symbol,Function}...; overwrite::Bool=false)
  D = readtable(df_file)
  transform!(D, feat_transforms...)
  fileroot, ext = splitext(df_file)
  f = overwrite ? df_file : fileroot * "_transform" * ext
  writetable(f, D)
  return f
end

function transform!(D::DataFrame, feat_transforms::Tuple{Symbol,Function}...)
  for (key, f) in feat_transforms
    D[key] = map(f, D[key])
  end
end

end #module
