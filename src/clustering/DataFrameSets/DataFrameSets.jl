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

export DFSet, DFSetLabeled, get_colnames, setlabels, setlabels!, load_from_dir, load_from_csvs,
        load_from_clusterresult
export sub, start, next, done, length

import Base: sub, start, next, done, length

using ClusterResults
using RLESUtils.FileUtils
using DataFrames

type DFSet
  names::Vector{ASCIIString}
  records::Vector{DataFrame}
end

type DFSetLabeled{T}
  names::Vector{ASCIIString}
  records::Vector{DataFrame}
  labels::Vector{T}
end

function DFSetLabeled{T}(Ds::DFSet, labels::Vector{T})
  @assert length(Ds.names) == length(Ds.records) == length(labels)
  DFSetLabeled(Ds.names, Ds.records, labels)
end

function load_from_dir(dir::AbstractString; ext::AbstractString="csv") #directory of csvs
  files = readdir_ext(ext, dir) |> sort!
  Ds = load_from_csvs(files)
  return Ds
end

function load_from_csvs(files::Vector{ASCIIString})
  records = map(readtable, files)
  fs = map(basename, files)
  return DFSet(fs, records)
end

function load_from_clusterresult{T1<:AbstractString,T2}(file::AbstractString, name2file::Dict{T1, T2})
  cr = load_result(file)
  return load_from_clusterresult(cr, name2file)
end
function load_from_clusterresult{T1<:AbstractString,T2}(cr::ClusterResult, name2file::Dict{T1, T2})
  files = map(cr.names) do x
    haskey(name2file, x) ? name2file[x] : error("key not found: $x")
  end
  records = map(readtable, files)
  return DFSetLabeled(cr.names, records, cr.labels)
end

get_colnames(Ds::DFSet) = get_colnames(Ds.records[1])
get_colnames(Dl::DFSetLabeled) = get_colnames(Dl.records[1])
get_colnames(D::DataFrame) = map(string, names(D))

sub(Ds::DFSet, i::Int64) = sub(Ds, i:i)
sub(Ds::DFSet, r::Range{Int64}) = DFSet(Ds.names[r], Ds.records[r])
sub(Ds::DFSet, v::Vector{Int64}) = DFSet(Ds.names[v], Ds.records[v])
sub(Dl::DFSetLabeled, i::Int64) = sub(Dl, i:i)
sub(Dl::DFSetLabeled, r::Range{Int64}) = DFSetLabeled(Dl.names[r], Dl.records[r], Dl.labels[r])
sub(Dl::DFSetLabeled, v::Vector{Int64}) = DFSetLabeled(Dl.names[v], Dl.records[v], Dl.labels[v])

function setlabels!{T}(Dl::DFSetLabeled{T}, labels::Vector{T})
  @assert length(Dl.records) == length(labels)
  Dl.labels = labels
  return Dl
end

function setlabels{T1, T2}(Dl::DFSetLabeled{T1}, labels::Vector{T2})
  @assert length(Dl.records) == length(labels)
  return DFSetLabeled{T2}(Dl.names, Dl.records, labels)
end

start(Ds::DFSet) = start(zip(Ds.names, Ds.records)) #TODO: don't zip every time
next(Ds::DFSet, s) = next(zip(Ds.names, Ds.records), s)
done(Ds::DFSet, s) = done(zip(Ds.names, Ds.records), s)
length(Ds::DFSet) = length(Ds.records)

start(Dl::DFSetLabeled) = start(zip(Dl.names, Dl.records, Dl.labels))
next(Dl::DFSetLabeled, s) = next(zip(Dl.names, Dl.records, Dl.labels), s)
done(Dl::DFSetLabeled, s) = done(zip(Dl.names, Dl.records, Dl.labels), s)
length(Dl::DFSetLabeled) = length(Dl.records)

containsNA(Ds::DFSet) = containsNA(Ds.records)
containsNA(Dl::DFSetLabeled) = containsNA(Dl.records)

function containsNA(records::Vector{DataFrame})
  out = false
  i = j = 1
  try
    while i <= length(records)
      while j <= length(D.columns)
        convert(Array, records[i].columns[j]) #will fail if contains NA
        j += 1
      end
      i += 1
    end
    out = false
  catch e
    println(e)
    println("Record $i, column $j contains an NA")
    out = true
  end
  println("No NAs")
  return out
end

end #module
