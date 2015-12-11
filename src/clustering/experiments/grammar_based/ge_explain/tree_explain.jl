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
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar_typed/GrammarDef.jl"))

using GrammarDef
using DecisionTrees #generic decisions trees based on callbacks
using DecisionTreesVis
using GBClassifiers
using DataFrameSets #TODO: simplify these using reexport.jl
using ClusterResults
using TikzQTrees
using RLESUtils: RNGWrapper, Obj2Dict, FileUtils, LatexUtils
using GrammaticalEvolution
using Iterators
using DataFrames
using StatsBase

const NMAC_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats/")
const NON_NMAC_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_non_nmacs_ts_feats/")
const W_ENT = 100 #entropy
const W_LEN = 0.1 #

const GENOME_SIZE = 500
const MAXWRAPS = 2
const DEFAULTCODE = :(eval(false))
const VERBOSITY = 1

function TESTMODE(testing::Bool)
  global MAX_FITNESS = 0.05
  global POP_SIZE = testing ? 50 : 5000
  global MINITERATIONS = testing ? 1 : 5
  global MAXITERATIONS = testing ? 1 : 20
  global MAXDEPTH = testing ? 2 : 4
end

TESTMODE(true)

function get_name2file_map(df_dir::ASCIIString) #maps encounter number to filename
  df_files = readdir_ext("csv", df_dir)
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

const ASCII_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/ascii_clusters.json")
const MYKEL_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/mykel.json")
const JOSH1_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/josh1.json")
const JOSH2_CR = Pkg.dir("RLESCAS/src/clustering/data/dasc_clusters/josh2.json")

function get_example_D()
  name2file = get_name2file_map(NMAC_DIR)
  Dl = load_from_clusterresult(MYKEL_CR, name2file)
  return D = Dl.records[1]
end

function simplify_fnames!{T<:AbstractString}(fnames::Vector{T})
  map!(fnames) do s
    s = replace(s, "trajSaveMCTS_ACASX_EvE_", "")
    s = replace(s, "_dataframe.csv", "")
    return s
  end
end

#Helpers
#################
function get_metrics{T}(predicts::Vector{Bool}, truth::Vector{T})
  true_ids = find(predicts)
  false_ids = find(!predicts)
  ent_pre = truth |> proportions |> entropy
  ent_true = !isempty(true_ids) ?
    truth[true_ids] |> proportions |> entropy : 0.0
  ent_false = !isempty(false_ids) ?
    truth[false_ids] |> proportions |> entropy : 0.0
  w1 = length(true_ids) / length(truth)
  w2 = length(false_ids) / length(truth)
  ent_post = w1 * ent_true + w2 * ent_false #miminize entropy after split
  info_gain = ent_pre - ent_post
  return (info_gain, ent_pre, ent_post) #entropy pre/post split
end

#Callbacks
#################
function get_fitness{T}(code::Expr, Dl::DFSetLabeled{T})
  f = to_function(code)
  predicts = map(f, Dl.records)
  _, _, ent_post = get_metrics(predicts, Dl.labels)
  return W_ENT * ent_post + W_LEN * length(string(code))
end

function get_truth(members::Vector{Int64}, Dl::DFSetLabeled{Int64})
  truth = Dl.labels[members]
  return truth::Vector{Int64}
end

function get_splitter(members::Vector{Int64}, Dl::DFSetLabeled{Int64}, gb_params::GeneticSearchParams)
  Dl_sub = Dl[members]
  classifier = train(gb_params, Dl_sub)

  predicts = GBClassifiers.classify(classifier, Dl_sub)
  info_gain, _, _ = get_metrics(predicts, Dl_sub.labels)

  return info_gain > 0 ? classifier : nothing
end

function get_labels(classifier::GBClassifier, members::Vector{Int64}, Dl::DFSetLabeled{Int64})
  labels = GBClassifiers.classify(classifier, Dl.records[members])
  return labels::Vector{Bool}
end

#callbacks for vis
################
function get_name(node::DTNode, Dl::DFSetLabeled{Int64})
  members_text = "members=" * join(Dl.names[node.members], ",")
  matched = ""
  mismatched = ""
  label = "label=$(node.label)"
  confidence = "confidence=" * string(signif(node.confidence, 3))
  text = join([members_text, matched, mismatched, label, confidence], "\n")
  return text::ASCIIString
end

get_height(node::DTNode) = node.depth


#Scripts
################

#explain flat clusters via decision tree, nmacs only
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script1(crfile::AbstractString)
  seed = 1
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  name2file = get_name2file_map(NMAC_DIR)
  Dl = load_from_clusterresult(crfile, name2file)
  Dl_check = deepcopy(Dl)
  #explain
  grammar = create_grammar()
  gb_params = GeneticSearchParams(grammar, GENOME_SIZE, POP_SIZE, MAXWRAPS, DEFAULTCODE, MAX_FITNESS,
                            MINITERATIONS, MAXITERATIONS, VERBOSITY, get_fitness)
  num_data = length(Dl)
  T1 = Bool #predict_type
  T2 = Int64 #label_type
  p = DTParams(num_data,
               (members::Vector{Int64}) -> get_truth(members, Dl),
               (members::Vector{Int64}) -> get_splitter(members, Dl, gb_params),
               (classifier::GBClassifier, members::Vector{Int64}) -> get_labels(classifier, members, Dl),
               MAXDEPTH, T1, T2)

  dtree = build_tree(p)

  #save fcrules
  fileroot = splitext(basename(crfile))[1]
  Obj2Dict.save_obj("$(fileroot)_fc.json", dtree)
  #check
  #check_result = checker(fcrules, Dl_check)
  #Obj2Dict.save_obj("$(fileroot)_fccheck.json", check_result)
  #visualize
  treedepth = get_max_depth(dtree)
  viscalls = VisCalls((node::DTNode) -> get_name(node, Dl),
                      get_height
                      )
  write_d3js(dtree, viscalls, "$(fileroot)_d3.json")
  return Dl, dtree
end

#=
#flat clusters explain -- include non-nmacs as an extra cluster
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script2(crfile::AbstractString)
  seed = 1
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  name2file = get_name2file_map(NMAC_DIR)
  Dl_nmac = load_from_clusterresult(crfile, name2file)
  new_id = maximum(Dl_nmac.labels) + 1
  D = load_from_dir(NON_NMAC_DIR)
  simplify_fnames!(D.names)
  Dl_non_nmac = DFSetLabeled(D, fill(new_id, length(D)))
  Dl = vcat(Dl_nmac, Dl_non_nmac)
  Dl_check = deepcopy(Dl)
  #explain
  p = FCParams()
  grammar = create_grammar()
  gb_params = GeneticSearchParams(grammar, GENOME_SIZE, POP_SIZE, MAXWRAPS, DEFAULTCODE, MAX_FITNESS,
                            MINITERATIONS, MAXITERATIONS, VERBOSITY, get_fitness)
  fcrules = explain_clusters(p, gb_params, Dl)
  #save fcrules
  fileroot = splitext(basename(crfile))[1]
  Obj2Dict.save_obj("$(fileroot)_fc.json", fcrules)
  #check
  check_result = checker(fcrules, Dl_check)
  Obj2Dict.save_obj("$(fileroot)_fccheck.json", check_result)
  #visualize
  plot_qtree(fcrules, Dl, outfileroot="$(fileroot)_qtree", check_result=check_result)
  return Dl, fcrules, check_result
end

#flat clusters explain, nmacs vs non-nmacs
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script3()
  seed = 1
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  D_nmac = load_from_dir(NMAC_DIR)
  simplify_fnames!(D_nmac.names)
  Dl_nmac = DFSetLabeled(D_nmac, fill(1, length(D_nmac)))
  D_non_nmac = load_from_dir(NON_NMAC_DIR)
  simplify_fnames!(D_non_nmac.names)
  Dl_non_nmac = DFSetLabeled(D_non_nmac, fill(2, length(D_non_nmac)))
  Dl = vcat(Dl_nmac, Dl_non_nmac)
  Dl_check = deepcopy(Dl)
  #explain
  p = FCParams()
  grammar = create_grammar()
  gb_params = GeneticSearchParams(grammar, GENOME_SIZE, POP_SIZE, MAXWRAPS, DEFAULTCODE, MAX_FITNESS,
                            MINITERATIONS, MAXITERATIONS, VERBOSITY, get_fitness)
  fcrules = explain_clusters(p, gb_params, Dl)
  #save fcrules
  fileroot = "nmacs_vs_nonnmacs"
  Obj2Dict.save_obj("$(fileroot)_fc.json", fcrules)
  #check
  check_result = checker(fcrules, Dl_check)
  Obj2Dict.save_obj("$(fileroot)_fccheck.json", check_result)
  #visualize
  plot_qtree(fcrules, Dl, outfileroot="$(fileroot)_qtree", check_result=check_result)
  return Dl, fcrules, check_result
end
=#
