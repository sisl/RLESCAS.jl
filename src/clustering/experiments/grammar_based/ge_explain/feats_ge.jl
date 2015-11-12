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
using ClusterRules
using GBClassifiers
using DataFrameSets
using ClusterResults
using TikzQTrees
using RLESUtils.FileUtils
using RLESUtils.LatexUtils
using Iterators
using DataFrames
using GrammaticalEvolution

const DF_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats/")
const GRAMMAR = create_grammar()
const W1 = 0.001 #code length
const GENOME_SIZE = 400
const POP_SIZE = 50#0
const MAXWRAPS = 2
const MINITERATIONS = 1#5
const MAXITERATIONS = 1#10
const DEFAULTCODE = :(eval(false))
const MAX_FITNESS = 0.03
const VERBOSITY = 1

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

function get_fitness{T}(code::Expr, Dsl::DFSetLabeled{T})
  f = to_function(code)
  predicted_labels = map(f, Dsl.records)
  err = count(identity, predicted_labels .!= Dsl.labels) / length(Dsl)
  return err > 0.0 ? err : W1 * length(string(code))
end

function fill_to_col!{T}(Ds::DFSet, field_id::Int64, fillvals::AbstractVector{T})
  @assert length(Ds) == length(fillvals)
  for i = 1:length(Ds)
    fill!(Ds[i].columns[field_id], fillvals[i])
  end
end

get_colnames(Ds::DFSet) = get_colnames(Ds.records[1])
get_colnames(Dsl::DFSetLabeled) = get_colnames(Dsl.records[1])
get_colnames(D::DataFrame) = map(string, names(D))

function qtreeflat{S<:String}(Dsl::DFSetLabeled, fcrules::FCRules, title::String, colnames::Vector{S})
  root_text = "$title\\$(join(Dsl.names,","))" |> escape_latex
  root = QTreeNode(root_text)
  for (label, classifier) in fcrules
    code_text = pretty_string(string(classifier.code), colnames)
    members_text = get_members_text(Dsl, label, classifier)
    cluster_text = "cluster=$label\\$(code_text)\\$(members_text)" |> escape_latex
    push!(root.children, QTreeNode(cluster_text))
  end
  return TikzQTree(root)
end

function get_members_text(Dsl::DFSetLabeled, label, classifier::GBClassifier)
  members = find(Dsl.labels .== label)
  truth = map(l -> l == label, Dsl.labels) #one vs rest truth
  pred = classify(classifier, Dsl)
  mismatches = find(pred .!= truth)
  ss = Dsl.names[members]
  #for i in mismatches
  #  ss[i] = "\\textunderline{$(ss[i])}"
  #end
  s = join(ss, ",")
  return s
end

function checker{T}(crfile::String, labels_codes::Vector{T})
  result = true
  Dsl = load_from_clusterresult(crfile, NAME2FILE_MAP)
  for (label, code) in labels_codes
    truth = map(l -> l == label, Dsl.labels)
    pred = classify(code, Dsl.records)
    matched = pred == truth
    println("pred=$pred, truth=$truth, matched=$matched")
    if !matched
      mismatched = count(identity, pred .!= truth)
      warn("Not matched: label=$label, mismatched=$mismatched")
      result = false
    end
  end
  return result
end

#script1(MYKEL_CR)
function script1(crfile::String)
  Dsl = load_from_clusterresult(crfile, NAME2FILE_MAP)
  p = FCParams()
  gb_params = GeneticSearchParams(GRAMMAR, GENOME_SIZE, POP_SIZE, MAXWRAPS, DEFAULTCODE, MAX_FITNESS,
                            MINITERATIONS, MAXITERATIONS, VERBOSITY, get_fitness)
  fcrules = explain_clusters(p, gb_params, Dsl)
  #checker(crfile, labels_classifiers)
  title = basename(crfile)
  qtree = qtreeflat(Dsl, fcrules, title, get_colnames(Dsl))
  fileroot = splitext(basename(crfile))[1]
  plottree(qtree, outfileroot="$(fileroot)_qtree")
  return fcrules
end

#=
function hcluster_codes(crfile::String)
  cr = load_result(crfile)
  tree = cr.tree
  nrecords = length(cr.names)
  A = Array(QTreeNode, nrecords)
  for i = 1:nrecords
    A[i] = QTreeNode()
  end
  for i = size(tree, 1) #rows
    c1, c2 = tree[i]

  end
end
=#

#TODOs:
#try to explain Mykel's clusterings?
#refactor tests
#visualization, d3?
#papers
#survey

#=
function samedir_firstRA!(Ds::DFSet, labels::Vector{Bool})
  vert_rate1, alarm1, resp_none1, target_rate1 = map(x -> Ds[1].colindex[x], [:vert_rate_1, :alarm_1, :response_none_1, :target_rate_1])
  for i = 1:length(Ds)
    col = Ds[i].columns
    for j = 1:length(col[vert_rate1])
      if col[alarm1][j] && col[resp_none1][j] #first RA
        s = sign(col[target_rate1][j])
        if s == 0.0
          col[vert_rate1][j] = labels[i] ? 0.0 : -1.0
        else #s not zero
          z = s * (abs(col[vert_rate1][j]) + 1.0) #same sign as target_rate_1, avoid 0.0 on vert_rate
          col[vert_rate1][j] = labels[i] ? z : -z
        end
      end
    end
  end
  #should give: Y(D[:,alarm1] && D[:,resp_none1], sn(D[:,:target_rate1], D[:,:vert_rate1]))
  #should give: Y(D[:,24] && D[:,30], sn(D[:,22], D[:,2]))
end

function script4()
  Ds, labels = get_Ds(1, 4)
  samedir_firstRA!(Ds, labels)
  #should give: Y(D[:,alarm1] && D[:,resp_none1], sn(D[:,:target_rate1], D[:,:vert_rate1]))
  #should give: Y(D[:,24] && D[:,30], sn(D[:,22], D[:,2]))
  (f, ind, pred) = learn_rule(Ds, labels)
end

function script5()
  Ds, labels = get_Ds(0, 2)
  samedir_firstRA!(Ds, labels)
  direct_sample(Ds, labels, 500, 100000)
end
=#

#=
function script1()
  Ds, labels = get_Ds(0,2)
  fill_to_col!(Ds, 1, !labels)
  #should give: all(!D[:,1])
  (f, ind, pred) = learn_rule(Ds, labels)
end

function script2()
  Ds, labels = get_Ds(0,2)
  fill_to_col!(Ds, 2, map(x -> x ? 25.0 : -5.0, labels))
  #should give: all(0.0 .<= D[:,2])
  (f, ind, pred) = learn_rule(Ds, labels)
end
=#

#=
function script6() #try to separate real clusters
  Dsl = load_from_clusterresult(ASCII_CR, NAME2FILE_MAP)
  label_map = one_vs_one_labelmap(Dsl.labels, 0, 2)
  Dsl = maplabels(Dsl, label_map)
  #not sure what to expect
  (f, ind, pred, code) = learn_rule(Dsl)
end

function script9() #real clusters 1 vs others
  Dsl = load_from_clusterresult(ASCII_CR, NAME2FILE_MAP)
  label_map = one_vs_all_labelmap(Dsl.labels, 3)
  Dsl = maplabels(Dsl, label_map)
  #not sure what to expect
  (f, ind, pred, code) = learn_rule(Dsl)
end

function script11() #1 on 1
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 5:6)
  labels = [false, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script12() #1 on others
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:5)
  labels = [false, true, true, true, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script13() #2 on others
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:4)
  labels = [false, false, true, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script14() #random clustering
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:6)
  labels = [false, true, false, true, false, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end

function script15() #random clustering
  Ds, files = load_from_dir(DF_DIR)
  Ds_ = sub(Ds, 1:10)
  labels = [false, false, true, true, false, false, true, true, false, true]
  (f, ind, pred) = learn_rule(Ds_, labels)
end
=#

#negate_expr(ex::Expr) = parse("!($ex)")
