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

include("process_jsons.jl")
include("time_series_features1.jl")

const DASC_JSON = Pkg.dir("RLESCAS/src/clustering/data/dasc/json")
const DASC_CSV = Pkg.dir("RLESCAS/src/clustering/data/dasc/csv")
const DASC_OUT = Pkg.dir("Datasets/data/dasc")
const DASC_META = Pkg.dir("Datasets/data/dasc_meta")

const LIBCAS098_SMALL_JSON = Pkg.dir("RLESCAS/src/clustering/data/libcas098_small/json")
const LIBCAS098_SMALL_CSV = Pkg.dir("RLESCAS/src/clustering/data/libcas098_small/csv")
const LIBCAS098_SMALL_OUT = Pkg.dir("Datasets/data/libcas098_small")
const LIBCAS098_SMALL_META = Pkg.dir("Datasets/data/libcas098_small_meta")

function script_dasc(fromjson::Bool=true)
  if fromjson
    convert2csvs(DASC_JSON, DASC_CSV)
  end

  tmpdir = mktempdir()
  csvs2dataframes(DASC_CSV, tmpdir)
  correct_coc_stays!(tmpdir)

  mv_files(tmpdir, DASC_OUT, name_from_id)
  add_encounter_info!(DASC_OUT)

  encounter_meta(DASC_JSON, DASC_META)
end

#from APL 20151230, libcas0.9.8, MCTS iterations=500, testbatch
function script_libcas098_small(fromjson::Bool=true)
  if fromjson
    convert2csvs(LIBCAS098_SMALL_JSON, LIBCAS098_SMALL_CSV)
  end

  tmpdir = mktempdir()
  csvs2dataframes(LIBCAS098_SMALL_CSV, tmpdir)
  correct_coc_stays!(tmpdir)

  mv_files(tmpdir, LIBCAS098_SMALL_OUT, name_from_id)
  add_encounter_info!(LIBCAS098_SMALL_OUT)

  encounter_meta(LIBCAS098_SMALL_JSON, LIBCAS098_SMALL_META)
end
