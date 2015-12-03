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
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar_fast/GrammarDef.jl"))

using GrammarDef
using ClusterRules
using ClusterRulesVis
using GBClassifiers
using DataFrameSets
using ClusterResults
using TikzQTrees
using RLESUtils: RNGWrapper, Obj2Dict, FileUtils, LatexUtils
using Iterators
using DataFrames
using GrammaticalEvolution

const DF_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats/")
const W_FPR = 100 #heavy weight on penalizing trues incorrect (intrcluster)
const W_FNR = 1 #normal weight on penalizing falses incorrect (extracluster)
const W_LEN = 0.001 #W_LEN x 50 chars = W_FNR * 0.05 tnr (50 characters equiv to 5% fnr increase)

const GENOME_SIZE = 400
const MAXWRAPS = 2
const DEFAULTCODE = :(eval(false))
const VERBOSITY = 1

const TESTMODE = false
const MAX_FITNESS = 0.05
const POP_SIZE = TESTMODE ? 50 : 5000
const MINITERATIONS = TESTMODE ? 1 : 5
const MAXITERATIONS = TESTMODE ? 1 : 20

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

function get_fitness{T}(code::Expr, Dl::DFSetLabeled{T})
  f = to_function(code)
  predicts = map(f, Dl.records)
  truth = Dl.labels
  true_ids = find(truth)
  false_ids = find(!truth)
  fpr = count(i -> predicts[i] != truth[i], true_ids) / length(true_ids) #frac of trues correctly classified
  fnr = count(i -> predicts[i] != truth[i], false_ids) / length(false_ids) #frac of falses correctly classified
  return W_FPR * fpr + W_FNR * fnr + W_LEN * length(string(code))
end

function fill_to_col!{T}(Ds::DFSet, field_id::Int64, fillvals::AbstractVector{T})
  @assert length(Ds) == length(fillvals)
  for i = 1:length(Ds)
    fill!(Ds[i].columns[field_id], fillvals[i])
  end
end

#flat clusters
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script1(crfile::AbstractString)
  seed = 1
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = load_from_clusterresult(crfile, NAME2FILE_MAP)
  #explain
  p = FCParams()
  grammar = create_grammar(Dl.records[1])
  gb_params = GeneticSearchParams(grammar, GENOME_SIZE, POP_SIZE, MAXWRAPS, DEFAULTCODE, MAX_FITNESS,
                            MINITERATIONS, MAXITERATIONS, VERBOSITY, get_fitness)
  fcrules = explain_clusters(p, gb_params, Dl)
  #save fcrules
  fileroot = splitext(basename(crfile))[1]
  Obj2Dict.save_obj("$(fileroot)_fc.json", fcrules)
  #check
  Dl2 = load_from_clusterresult(crfile, NAME2FILE_MAP) #reload in case Dl got changed
  check_result = checker(fcrules, Dl2)
  Obj2Dict.save_obj("$(fileroot)_fccheck.json", check_result)
  #visualize
  plot_qtree(fcrules, Dl, outfileroot="$(fileroot)_qtree", check_result=check_result)
  return Dl, fcrules, check_result
end

#=
#hierarchical clusters
#script2(ASCII_CR)
function script2(crfile::AbstractString)
  seed = 1
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  cr = load_result(crfile)
  Dl = load_from_clusterresult(cr, NAME2FILE_MAP)
  #explain
  p = HCParams(cr.tree)
  grammar = create_grammar(Dl.records[1])
  gb_params = GeneticSearchParams(grammar, GENOME_SIZE, POP_SIZE, MAXWRAPS, DEFAULTCODE, MAX_FITNESS,
                            MINITERATIONS, MAXITERATIONS, VERBOSITY, get_fitness)
  hcrules = explain_clusters(p, gb_params, Dl)
  #save hcrules
  fileroot = splitext(basename(crfile))[1]
  Obj2Dict.save_obj("$(fileroot)_hc.json", hcrules)
  #check
  cr2 = load_result(crfile)
  Dl2 = load_from_clusterresult(cr2, NAME2FILE_MAP)
  check_result = checker(hcrules, Dl2)
  Obj2Dict.save_obj("$(fileroot)_hccheck.json", check_result)
  #visualize
  write_d3js(hcrules, Dl, outfileroot="$(fileroot)_d3js", check_result=check_result)
  return Dl, hcrules, check_result
end
=#
