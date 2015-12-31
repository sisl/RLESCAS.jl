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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl")) #clustering packages
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar_typed/GrammarDef.jl")) #grammar

const MAINDIR = dirname(@__FILE__)
push!(LOAD_PATH, MAINDIR)

using GrammarDef
using DescriptionMap
using Datasets
using DataFrameSets
using GBClassifiers
using DecisionTrees #generic decisions trees based on callbacks
using DecisionTreeVis
using SyntaxTrees
using SyntaxTreePretty
using TikzQTrees
using TreeExplainVis
using RLESUtils: RNGWrapper, Obj2Dict, FileUtils, StringUtils, ArrayUtils, Observers, Loggers
using GrammaticalEvolution
using Iterators
using DataFrames
using DataFramesMeta
using StatsBase

const W_ENT = 100 #entropy
const W_LEN = 0.1 #

const GENOME_SIZE = 500
const MAXWRAPS = 2
const DEFAULTCODE = :(eval(false))
const TOP_PERCENT = 0.5
const PROB_MUTATION = 0.2
const MUTATION_RATE = 0.2
const VERBOSITY = 1
const MAXVALUE = 1000

const MAN_JOSH1 = "josh1"
const MAN_JOSH2 = "josh2"
const MAN_MYKEL = "mykel"

const WRAP_MEMBERS = 30
const HIST_NBINS = 40
const HIST_EDGES = linspace(0.0, 200.0, HIST_NBINS + 1)
const HIST_MIDS = Base.midpoints(HIST_EDGES) |> collect

function TESTMODE(testing::Bool)
  global POP_SIZE = testing ? 50 : 5000
  global MAXITERATIONS = testing ? 3 : 50
  global STOP_N = MAXITERATIONS #testing ? 3 : 10 #early stop
  global MAXDEPTH = testing ? 2 : 4
end

TESTMODE(true)

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

function get_truth{T}(members::Vector{Int64}, Dl::DFSetLabeled{T})
  truth = Dl.labels[members]
  return truth::Vector{T}
end

function get_splitter(members::Vector{Int64}, Dl::DFSetLabeled{Int64},
                      gb_params::GeneticSearchParams, logs::TaggedDFLogger)
  observer = gb_params.observer
  empty!(observer)
  decision_id = nrow(logs["fitness"]) > 0 ?
    maximum(logs["fitness"][:decision_id]) + 1 : 1
  add_observer(observer, "fitness", append_push!_f(logs, "fitness", decision_id))
  add_observer(observer, "fitness5", x -> begin
                 iter = x[1]
                 fitness = x[2:end]
                 for i in eachindex(fitness)
                   push!(logs, "fitness5", [iter, i, fitness[i], decision_id])
                 end
               end)
  add_observer(observer, "code", append_push!_f(logs, "code", decision_id))
  add_observer(observer, "population", x -> begin
                 iter, pop = x
                 fitness_vec = Float64[pop[i].fitness  for i = 1:length(pop)]
                 edges, counts = hist(fitness_vec, HIST_EDGES)
                 uniq_fitness = Int64[]
                 uniq_code = Int64[]
                 for (e1, e2) in partition(HIST_EDGES, 2, 1)
                   subids = filter(i -> e1 <= pop[i].fitness < e2, 1:length(pop))
                   subpop = pop[subids]
                   n_fit = length(unique(imap(i -> string(subpop[i].fitness), 1:length(subpop))))
                   n_code = length(unique(imap(i -> string(subpop[i].code), 1:length(subpop))))
                   push!(uniq_fitness, n_fit)
                   push!(uniq_code, n_code)
                 end
                 for (m, c, uf, uc) in zip(HIST_MIDS, counts, uniq_fitness, uniq_code)
                   push!(logs, "pop_distr", [iter, m, c, uf, uc, decision_id])
                 end
               end)
  add_observer(observer, "population", x -> begin
                 iter, pop = x
                 n_fit = length(unique(imap(i -> string(pop[i].fitness), 1:length(pop))))
                 n_code = length(unique(imap(i -> string(pop[i].code), 1:length(pop))))
                 push!(logs, "pop_diversity", [iter, n_fit, n_code, decision_id])
               end)
  add_observer(observer, "iteration_time", append_push!_f(logs, "iteration_time", decision_id))
  add_observer(observer, "computeinfo", append_push!_f(logs, "computeinfo", decision_id))

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
const COLNAMES = begin
  D = dataset("dasc", "tsfeats1")
  cols = setdiff(names(D), [:NMAC, :label, :t, :encounter_id])
  map(string, cols) #return
end
const COLNAMES_FULL = map(x -> DESCRIP_MAP[x], COLNAMES)
const FMT_PRETTY = get_format_pretty(COLNAMES)
const FMT_NATURAL = get_format_natural(COLNAMES_FULL)

function get_name(node::DTNode, Dl::DFSetLabeled{Int64})
  members = sort(Dl.names[node.members], by=x->parse(Int64, x))
  tmp = ASCIIString[]
  if length(members) <= WRAP_MEMBERS
    push!(tmp, join(members, ",")) #push all of it
  else
    for mems in partition(members, WRAP_MEMBERS) #split
      push!(tmp, join(mems, ","))
    end
  end
  members_text = "members=" * join(tmp, "\\\\")
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
    fitness = "fitness=" * string(signif(node.split_rule.fitness, 4))
  else
    natural = rule = "none"
    fitness = "fitness=none"
  end
  text = join([members_text, label, confidence, rule, natural, fitness], "\\\\")
  return text::ASCIIString
end

get_height(node::DTNode) = node.depth

function rem_double_nots(node::STNode)
  while node.cmd == "!" && node.args[1].cmd == "!"
    node = node.args[1].args[1]
  end
  return node
end

function define_logger()
  logger = TaggedDFLogger()
  add_folder!(logger, "fitness", [Int64, Float64, Int64], ["iter", "fitness", "decision_id"])
  add_folder!(logger, "fitness5", [Int64, Int64, Float64, Int64],
              ["iter", "position", "fitness", "decision_id"])
  add_folder!(logger, "code", [Int64, ASCIIString, Int64], ["iter", "code", "decision_id"])
  add_folder!(logger, "pop_distr", [Int64, Float64, Int64, Int64, Int64, Int64],
              ["iter", "bin_center", "count", "unique_fitness", "unique_code", "decision_id"])
  add_folder!(logger, "pop_diversity", [Int64, Int64, Int64, Int64],
              ["iter", "unique_fitness", "unique_code", "decision_id"])
  add_folder!(logger, "iteration_time", [Int64, Float64, Int64],
              ["iter", "iteration_time_s", "decision_id"])
  add_folder!(logger, "computeinfo", [ASCIIString, ASCIIString, ASCIIString, ASCIIString, Int64],
              ["startdatetime", "enddatetime", "hostname", "git_hash", "decision_id"])
  return logger
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

  #gb_params = BestSampleParams(grammar, GENOME_SIZE, MAXVALUE, MAXWRAPS,
  #                                DEFAULTCODE, 5000, VERBOSITY, get_fitness,
  #                                Observer())

  logs = define_logger()
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
function to_DFSetLabeled(D::DataFrame, labelcol::Symbol, labeltype::Type;
                         exclude::Vector{Symbol}=Symbol[])
  Dl = DFSetLabeled(labeltype)
  for subdf in DataFrames.groupby(D, :encounter_id)
    name = string(subdf[:encounter_id][1]) #they should all be the same
    label::labeltype = subdf[labelcol][1] #they should all be the same
    cols = setdiff(names(subdf), exclude) #remove labels
    record = subdf[cols]
    push!(Dl, name, record, label)
  end
  return Dl
end

function nmac_clusters(clustering::AbstractString)
  D = dataset("dasc", "tsfeats1")
  D = D[D[:NMAC], :] #NMACs only
  labels = dataset("dasc_manual", clustering)
  D = join(D, labels, on=:encounter_id) #join by encounters
  return to_DFSetLabeled(D, :label, Int64, exclude=[:label, :NMAC])
end

function nonnmacs_extra_cluster(clustering::AbstractString)
  D = dataset("dasc", "tsfeats1")
  labels = dataset("dasc_manual", clustering)
  D = join(D, labels, on=:encounter_id, kind=:left)
  n = maximum(D[!isna(D[:label]), :label]) + 1 #avoid NA poisoning
  @byrow! D if isna(:label); :label = n end
  return to_DFSetLabeled(D, :label, Int64, exclude=[:label, :NMAC])
end

function nmacs_vs_nonnmacs()
  D = dataset("dasc", "tsfeats1")
  D[:NMAC]=map(x->x ? 1 : 2, D[:NMAC])
  return to_DFSetLabeled(D, :NMAC, Int64, exclude=[:label, :NMAC])
end

function tree_vis{T}(dtree::DecisionTree, Dl::DFSetLabeled{T}, fileroot::AbstractString)
  viscalls = VisCalls((node::DTNode) -> get_name(node, Dl), get_height)
  write_d3js(dtree, viscalls, "$(fileroot)_d3.json")
  plottree("$(fileroot)_d3.json", outfileroot="$(fileroot)_d3")
end

function log_vis(logs::TaggedDFLogger, fileroot::ASCIIString="logs")
  plot_pop_distr(logs["pop_distr"], "$(fileroot)_popdistr.gif")
  plot_fitness(logs["fitness"], "$(fileroot)_fitness.pdf")
  plot_fitness5(logs["fitness5"], "$(fileroot)_fitness5.pdf")
  plot_pop_diversity(logs["pop_diversity"], "$(fileroot)_popdiversity.pdf")
  plot_itertime(logs["iteration_time"], "$(fileroot)_itertime.pdf")
end

#Scripts
################

#explain flat clusters via decision tree, nmacs only
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script1(dataname::AbstractString; seed::Int64=1)
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = nmac_clusters(dataname)

  #explain
  dtree, logs = train_dtree(Dl)

  #save to json
  Obj2Dict.save_obj("$(dataname)_fc.json", dtree)
  save_log("$(dataname)_logs.txt", logs)

  #visualize
  tree_vis(dtree, Dl, dataname)
  log_vis(logs, "$(dataname)_logs")

  return dtree, logs
end

function script1_vis(dataname::AbstractString)
  #load data
  Dl = nmac_clusters(dataname)

  #load obj
  dtree = Obj2Dict.load_obj("$(dataname)_fc.json")
  logs = load_log("$(dataname)_logs.txt")

  #visualize
  tree_vis(dtree, Dl, dataname)
  log_vis(logs, "$(dataname)_logs")
end

#flat clusters explain -- include non-nmacs as an extra cluster
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script2(dataname::AbstractString; seed::Int64=1)
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = nonnmacs_extra_cluster(dataname)

  #explain
  dtree, logs = train_dtree(Dl)

  #save to json
  Obj2Dict.save_obj("$(dataname)_fc.json", dtree)
  save_log("$(dataname)_logs.txt", logs)

  #visualize
  tree_vis(dtree, Dl, dataname)
  log_vis(logs, "$(dataname)_logs")

  return dtree, logs
end

function script2_vis(dataname::AbstractString)
  #load data
  Dl = nonnmacs_extra_cluster(dataname)

  #load obj
  dtree = Obj2Dict.load_obj("$(dataname)_fc.json")
  logs = load_log("$(dataname)_logs.txt")

  #visualize
  tree_vis(dtree, Dl, dataname)
  log_vis(logs, "$(dataname)_logs")
end

#flat clusters explain, nmacs vs non-nmacs
#script1(MYKEL_CR)
#script1(JOSH1_CR)
function script3(; seed::Int64=1)
  rsg = RSG(1, seed)
  set_global(rsg)

  #load data
  Dl = nmacs_vs_nonnmacs()

  #explain
  dtree, logs = train_dtree(Dl)

  #save to json
  fileroot = "nmacs_vs_nonnmacs"
  Obj2Dict.save_obj("$(fileroot)_fc.json", dtree)
  save_log("$(fileroot)_logs.txt", logs)

  #visualize
  tree_vis(dtree, Dl, fileroot)
  log_vis(logs, "$(fileroot)_logs")

  return dtree, logs
end

function script3_vis(fileroot::AbstractString="nmacs_vs_nonnmacs")
  #load data
  Dl = nmacs_vs_nonnmacs()

  #load obj
  dtree = Obj2Dict.load_obj("$(fileroot)_fc.json")
  logs = load_log("$(fileroot)_logs.txt")

  #visualize
  tree_vis(dtree, Dl, fileroot)
  log_vis(logs, "$(fileroot)_logs")
end

