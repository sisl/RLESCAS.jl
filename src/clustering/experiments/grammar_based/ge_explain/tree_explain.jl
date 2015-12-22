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
include("DescriptionMap.jl")

using GrammarDef
using DecisionTrees #generic decisions trees based on callbacks
using DecisionTreeVis
using SyntaxTrees
using SyntaxTreePretty
using GBClassifiers
using DataFrameSets #TODO: simplify these using reexport.jl
using ClusterResults
using TikzQTrees
using DescriptionMap
using RLESUtils: RNGWrapper, Obj2Dict, FileUtils, DataFramesUtils, StringUtils, ArrayUtils, Observers, Loggers, Organizers
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
const TOP_PERCENT = 0.4
const PROB_MUTATION = 0.2
const MUTATION_RATE = 0.2
const VERBOSITY = 1

function TESTMODE(testing::Bool)
  global POP_SIZE = testing ? 50 : 5000
  global STOP_N = testing ? 2 : 10
  global MAXITERATIONS = testing ? 1 : 30
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
  fname = joinpath(NMAC_DIR, readdir(NMAC_DIR)[1])
  return D = fname |> readtable
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
function stop(tracker::Vector{Float64}, iter::Int64, fitness::Float64)
  if iter == 1
    empty!(tracker)
  end
  push!(tracker, fitness)

  if length(tracker) < STOP_N
    return false
  else
    last_N = tracker[end - STOP_N + 1 : end]
    return elements_equal(last_N)
  end
end

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

function get_splitter(members::Vector{Int64}, Dl::DFSetLabeled{Int64}, gb_params::GeneticSearchParams, logs::Organizer)
  observer = gb_params.observer
  empty!(observer)
  log1 = DataFrameLogger([Int64, Float64], ["iter", "fitness"])
  log2 = ArrayLogger()
  add_observer(observer, "fitness", log1.f)
  add_observer(observer, "population", x -> begin
                 pop = x[1]
                 fitness_vec = Float64[pop[i].fitness  for i = 1:length(pop)]
                 edges, counts = hist(fitness_vec, 20)
                 edges = collect(edges)
                 mids = Array(Float64, length(edges) - 1)
                 for (i, edge) in enumerate(partition(edges, 2, 1))
                   mids[i] = mean(edge)
                 end
                 D = Dict{ASCIIString,Any}()
                 D["mids"] =  mids
                 D["counts"] = counts
                 D["top10"] = fitness_vec[1:10]
                 push!(log2, D)
               end)
  tagged_push!(logs, "fitness", log1)
  tagged_push!(logs, "population", log2)

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
const COLNAMES = get_example_D() |> get_col_names
const COLNAMES_FULL = map(x -> DESCRIP_MAP[x], COLNAMES)
const FMT_PRETTY = get_format_pretty(COLNAMES)
const FMT_NATURAL = get_format_natural(COLNAMES_FULL)

using Debug
@debug function get_name(node::DTNode, Dl::DFSetLabeled{Int64})
  @bp
  members = sort(Dl.names[node.members], by=x->parse(Int64, x))
  tmp = ["members="]
  for mems in partition(members, 30)
    push!(tmp, join(mems, ","))
  end
  members_text = join(tmp, "\\\\")
  #matched = ""
  #mismatched = ""
  label = "label=$(node.label)"
  confidence = "confidence=" * string(signif(node.confidence, 3))
  if isdefined(node.split_rule, :code)
    tree = SyntaxTree(string(node.split_rule.code))
    visit!(tree, rem_double_nots) #remove double nots
    rule = pretty_string(tree, FMT_PRETTY)
    s = pretty_string(tree, FMT_NATURAL)
    natural = uppercase_first(s)
  else
    natural = rule = "none"
  end
  text = join([members_text, label, confidence, rule, natural], "\\\\")
  return text::ASCIIString
end

get_height(node::DTNode) = node.depth

function rem_double_nots(node::STNode)
  while node.cmd == "!" && node.args[1].cmd == "!"
    node = node.args[1].args[1]
  end
  return node
end

function train_dtree{T}(Dl::DFSetLabeled{T})
  #explain
  grammar = create_grammar()
  fitness_tracker = Float64[]
  gb_params = GeneticSearchParams(grammar, GENOME_SIZE, POP_SIZE, MAXWRAPS,
                                  TOP_PERCENT, PROB_MUTATION, MUTATION_RATE, DEFAULTCODE,
                                  MAXITERATIONS, VERBOSITY, get_fitness,
                                  (iter, fitness) -> stop(fitness_tracker, iter, fitness),
                                  Observer())
  logs = Organizer()
  num_data = length(Dl)
  T1 = Bool #predict_type
  T2 = Int64 #label_type
  p = DTParams(num_data,
               (members::Vector{Int64}) -> get_truth(members, Dl),
               (members::Vector{Int64}) -> get_splitter(members, Dl, gb_params, logs),
               (classifier::GBClassifier, members::Vector{Int64}) -> get_labels(classifier, members, Dl),
               MAXDEPTH, T1, T2)

  dtree = build_tree(p)
  return dtree, logs
end

################
function nmac_clusters(crfile::AbstractString)
  name2file = get_name2file_map(NMAC_DIR)
  Dl = load_from_clusterresult(crfile, name2file)
  return Dl
end

function nonnmacs_extra_cluster(crfile::AbstractString)
  name2file = get_name2file_map(NMAC_DIR)
  Dl_nmac = load_from_clusterresult(crfile, name2file)
  new_id = maximum(Dl_nmac.labels) + 1
  D = load_from_dir(NON_NMAC_DIR)
  simplify_fnames!(D.names)
  Dl_non_nmac = DFSetLabeled(D, fill(new_id, length(D)))
  Dl = vcat(Dl_nmac, Dl_non_nmac)
  return Dl
end

function nmacs_vs_nonnmacs()
  D_nmac = load_from_dir(NMAC_DIR)
  simplify_fnames!(D_nmac.names)
  Dl_nmac = DFSetLabeled(D_nmac, fill(1, length(D_nmac)))
  D_non_nmac = load_from_dir(NON_NMAC_DIR)
  simplify_fnames!(D_non_nmac.names)
  Dl_non_nmac = DFSetLabeled(D_non_nmac, fill(2, length(D_non_nmac)))
  Dl = vcat(Dl_nmac, Dl_non_nmac)
  return Dl
end

function tree_vis{T}(dtree::DecisionTree, Dl::DFSetLabeled{T}, fileroot::AbstractString)
  viscalls = VisCalls((node::DTNode) -> get_name(node, Dl), get_height)
  write_d3js(dtree, viscalls, "$(fileroot)_d3.json")
  plottree("$(fileroot)_d3.json", outfileroot="$(fileroot)_d3")
end

#Scripts
################

#explain flat clusters via decision tree, nmacs only
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script1(crfile::AbstractString)
  seed = 2
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = nmac_clusters(crfile)

  #explain
  dtree, logs = train_dtree(Dl)

  #save to json
  fileroot = splitext(basename(crfile))[1]
  Obj2Dict.save_obj("$(fileroot)_fc.json", dtree)
  Obj2Dict.save_obj("$(fileroot)_logs.json", logs)

  #visualize
  tree_vis(dtree, Dl, fileroot)

  return dtree, logs
end

function script1_vis(crfile::AbstractString)
  Dl = nmac_clusters(crfile)
  fileroot = splitext(basename(crfile))[1]
  dtree = Obj2Dict.load_obj("$(fileroot)_fc.json")
  tree_vis(dtree, Dl, fileroot)
end

#flat clusters explain -- include non-nmacs as an extra cluster
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script2(crfile::AbstractString)
  seed = 1
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = nonnmacs_extra_cluster(crfile)

  #explain
  dtree, logs = train_dtree(Dl)

  #save to json
  fileroot = splitext(basename(crfile))[1]
  Obj2Dict.save_obj("$(fileroot)_fc.json", dtree)
  Obj2Dict.save_obj("$(fileroot)_logs.json", logs)

  #visualize
  tree_vis(dtree, Dl, fileroot)

  return dtree, logs
end

function script2_vis(crfile::AbstractString)
  #load data
  Dl = nonnmacs_extra_cluster(crfile)

  #load obj
  fileroot = splitext(basename(crfile))[1]
  dtree = Obj2Dict.load_obj("$(fileroot)_fc.json")

  #visualize
  tree_vis(dtree, Dl, fileroot)
end

#flat clusters explain, nmacs vs non-nmacs
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script3()
  seed = 2
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = nmacs_vs_nonnmacs()

  #explain
  dtree, logs = train_dtree(Dl)

  #save to json
  fileroot = "nmacs_vs_nonnmacs"
  Obj2Dict.save_obj("$(fileroot)_fc.json", dtree)
  Obj2Dict.save_obj("$(fileroot)_logs.json", logs)

  #visualize
  tree_vis(dtree, Dl, fileroot)

  return dtree, logs
end

