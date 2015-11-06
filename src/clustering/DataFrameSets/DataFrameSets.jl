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

module DataFrameSets

export DFSet, DFSetLabeled, get_colnames, maplabels, load_from_dir, load_from_csvs, load_from_clusterresult
export sub, start, next, done, length

import Base: sub, start, next, done, length

using ClusterResults
using RLESUtils.FileUtils
using DataFrames

type DFSet
  records::Vector{DataFrame}
end

type DFSetLabeled{T}
  records::Vector{DataFrame}
  labels::Vector{T}
end

function DFSetLabeled{T}(Ds::DFSet, labels::Vector{T})
  @assert length(Ds.records) == length(labels)
  DFSetLabeled(Ds.records, labels)
end

function load_from_dir(dir::String; ext::String="csv") #directory of csvs
  files = readdir_ext(ext, dir) |> sort!
  Ds = load_from_csvs(files)
  return (Ds, files)
end

function load_from_csvs(files::Vector{ASCIIString})
  Ds = map(readtable, files) |> DFSet
  return Ds
end

function load_from_clusterresult(file::String, name2file::Dict{ASCIIString, ASCIIString})
  cr = load_result(file)
  return load_from_clusterresult(cr, name2file)
end

function load_from_clusterresult(cr::ClusterResult, name2file::Dict{ASCIIString, ASCIIString})
  files = map(cr.names) do x
    haskey(name2file, x) ? name2file[x] : error("key not found: $x")
  end
  records = load_from_csvs(files)
  return DFSetLabeled(records, cr.labels)
end

function maplabels(Dsl::DFSetLabeled, label_map::Dict)
  ks = keys(label_map)
  inds = find(x -> in(x, ks), Dsl.labels)
  labels = map(x -> label_map[x], Dsl.labels[inds])
  Dsl_ = DFSetLabeled(Dsl.records[inds], labels)
  return Dsl_
end

get_colnames(Ds::DFSet) = map(string, names(Ds.records[1]))

sub(Ds::DFSet, i::Int64) = sub(Ds, i:i)
sub(Ds::DFSet, r::Range{Int64}) = DFSet(Ds.records[r])
sub(Dsl::DFSetLabeled, i::Int64) = sub(Ds, i:i)
sub(Dsl::DFSetLabeled, r::Range{Int64}) = DFSetLabeled(Dsl.records[r], Dsl.labels[r])
sub(Dsl::DFSetLabeled, v::Vector{Int64}) = DFSetLabeled(Dsl.records[v], Dsl.labels[v])

start(Ds::DFSet) = start(Ds.records)
next(Ds::DFSet, s) = next(Ds.records, s)
done(Ds::DFSet, s) = done(Ds.records, s)
length(Ds::DFSet) = length(Ds.records)

start(Dsl::DFSetLabeled) = start(zip(Dsl.records, Dsl.labels))
next(Dsl::DFSetLabeled, s) = next(zip(Dsl.records, Dsl.labels), s)
done(Dsl::DFSetLabeled, s) = done(zip(Dsl.records, Dsl.labels), s)
length(Dsl::DFSetLabeled) = length(Dsl.records)

end
