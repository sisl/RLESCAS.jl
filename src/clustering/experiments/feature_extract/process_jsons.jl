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
# ***********************************************i******************************

include(Pkg.dir("RLESCAS/src/converters/json_to_csv.jl"))

using RLESUtils.FileUtils

#read a directory of jsons and output csvs
function convert2csvs(in_dir::AbstractString, out_dir::AbstractString)
  if !isdir(out_dir) #create output dir if it doesn't exist
    mkpath(out_dir)
  end

  files = readdirGZs(in_dir)
  for f in files
    println("file = ", f)
    json_to_csv(f)
  end
  csvfiles = readdir_ext(".csv", in_dir) #readdir only gives basenames
  for src in csvfiles
    dst = joinpath(out_dir, basename(src))
    mv(src, dst, remove_destination=true)
  end
end

function encounter_meta(in_dir::AbstractString, out_dir::AbstractString)
  if !isdir(out_dir) #create output dir if it doesn't exist
    mkpath(out_dir)
  end

  files = readdirGZs(in_dir)
  colnames = Symbol[:encounter_id, :nmac]
  coltypes = Type[Int64, Bool]

  D = DataFrame(coltypes, colnames, 0)
  for f in files
    id = get_id(f)
    push!(D, [id, is_nmac(f)])
  end
  outfile = joinpath(out_dir, "encounter_meta.csv.gz")
  writetable(outfile, D)
end
