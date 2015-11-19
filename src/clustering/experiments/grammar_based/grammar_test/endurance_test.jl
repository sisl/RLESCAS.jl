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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl"))
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammardef.jl"))

using GrammarDef
using GBClassifiers
using DataFrameSets
using ClusterResults
using RLESUtils: RNGWrapper, Obj2Dict, FileUtils, LatexUtils

const SEED = 1

const DF_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats/")
const GRAMMAR = create_grammar()
const GENOME_SIZE = 400
const MAXVALUE = 1000
const MAXWRAPS = 2
const DEFAULTCODE = :(eval(false))
const NSAMPLES = 1000000
const VERBOSITY = 2

function get_name2file_map() #maps encounter number to filename
  df_files = readdir_ext("csv", DF_DIR)
  ks = map(df_files) do f
    s = basename(f)
    s = replace(s, "trajSaveMCTS_ACASX_EvE_", "")
    return replace(s, "_dataframe.csv", "")
  end
  name2file_map = Dict{ASCIIString, ASCIIString}()
  for (k, f) in zip(ks, df_files)
    name2file_map[k] = f
  end
  return name2file_map
end

const NAME2FILE_MAP = get_name2file_map()
const ASCII_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/ascii_clusters.json")
const MYKEL_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/mykel.json")
const JOSH1_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/josh1.json")
const JOSH2_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/josh2.json")

function script1(crfile::String)
  rsg = RSG(1, SEED) |> set_global
  Dl = load_from_clusterresult(crfile, NAME2FILE_MAP)
  len = length(Dl)
  half = div(len, 2)
  labels = vcat(fill(true, half), fill(false, len - half)) #half true, half false
  Dl_ = setlabels(Dl, labels)
  p = BestSampleParams(GRAMMAR, GENOME_SIZE, MAXVALUE, MAXWRAPS, DEFAULTCODE, NSAMPLES, VERBOSITY, nothing)
  classifier = train(p, Dl_)
end
