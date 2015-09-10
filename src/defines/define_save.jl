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

using JSON
using GZip

typealias SaveDict Dict{String, Any}

function trajSave(fileroot::String, d::SaveDict; compress::Bool=true)

  if compress
    outfile = string(fileroot, ".json.gz")
    f = GZip.open(outfile, "w")
  else
    outfile = string(fileroot, ".json")
    f = open(outfile, "w")
  end

  JSON.print(f, d)
  close(f)

  return outfile
end

function trajLoad(infile::String)

  if isCompressedSave(infile)
    #compressed
    f = GZip.open(infile, "r")
  elseif isRawSave(infile)
    #raw json
    f = open(infile, "r")
  else
    error("Invalid file type.  Expected .gz or .json extension.")
  end

  d = JSON.parse(f)
  close(f)

  return d
end

function readdirExt(ext::String, dir::String = ".")

  #ext should start with a '.' to be a valid extension
  @assert ext[1] == '.'

  files = readdir(dir)
  filter!(f -> splitext(f)[2] == ext, files)

  return String[joinpath(dir, f) for f in files]
end

readdirJSONs(dir::String=".") = readdirExt(".json", dir)

readdirGZs(dir::String=".") = readdirExt(".gz", dir)

readdirSaves(dir::String=".") = vcat(readdirJSONs(dir), readdirGZs(dir))

isRawSave(f::String) = splitext(f)[2] == ".json"

isCompressedSave(f::String) = splitext(f)[2] == ".gz"

isSave(f::String) = isRawSave(f) || isCompressedSave(f)

function getSaveFileRoot(f::String)

  if isCompressedSave(f)
    j = splitext(f)[1] #contains .json, need to split again
    fileroot = splitext(j)[1]
  else #raw save
    fileroot = splitext(f)[1]
  end

  return fileroot
end
