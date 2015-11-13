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

module ClusterRules

export CRParams, explain_clusters, checker, FCParams, FCRules, HCParams, HCRules
export start, next, done, length

using GBClassifiers
using DataFrameSets
import Base: start, next, done, length

abstract CRParams

#flat clustering
type FCParams <: CRParams
end

type FCRules{T} #T = typeof(labels)
  rules::Dict{T, GBClassifier}
end

#hierarchical clustering
type HCParams <: CRParams
  tree::Array{Int64,2} #as a merge matrix starting from 1, input data indexed as 1:length(Dl)
end

type HCElement
  members::Vector{Int64}
  classifier::Union(GBClassifier, Nothing)
  children::Dict{Bool,Int64}
end

type HCRules
  tree::Array{Int64,2} #as a merge matrix starting from 1, input data indexed as 1:length(Dl)
  rules::Vector{HCElement}
end

type CheckResult
  matched::Vector{Int64} #indices into Dl
  mismatched::Vector{Int64} #indices into Dl
end
CheckResult() = CheckResult(Int64[], Int64[])

#explain flat clustering
function explain_clusters{T}(p::FCParams, gb_params::GBParams, Dl::DFSetLabeled{T})
  labelset = unique(Dl.labels) |> sort!
  classifiers = pmap(labelset) do l
    labels = map(x -> x == l, Dl.labels) #one vs others mapping
    Dl_ = setlabels(Dl, labels) #new Dl
    return train(gb_params, Dl_) #out=classifier
  end
  rules = Dict{T, GBClassifier}(labelset, classifiers)
  return FCRules(rules)
end

function checker{T}(fcrules::FCRules, Dl::DFSetLabeled{T})
  results = Dict{T,Any}()
  for (label, classifier) in fcrules
    truth = map(l -> l == label, Dl.labels)
    pred = classify(classifier, Dl)
    matched = find(pred .== truth) #indices
    mismatched = find(pred .!= truth) #indices
    results[label] = CheckResult(matched, mismatched)
    println("label=$label, matched=$(length(matched)), mismatched=$(length(mismatched))")
    if length(mismatched) != 0
      warn("Not matched: label=$label, mismatched=$(Dl.names[mismatched])")
    end
  end
  return results
end

function explain_clusters{T}(p::HCParams, gb_params::GBParams, Dl::DFSetLabeled{T})
  @assert size(p.tree, 2) == 2 #should have exactly 2 columns for the clusters to be merged
  @assert all(p.tree .> 0) #should be 1-indexed
  ndata = length(Dl)
  top_index = maximum(p.tree) + 1
  V = Array(HCElement, top_index)
  for i = 1:ndata
    members = Int64[i]
    classifier = nothing
    children = Dict{Bool, Int64}()
    V[i] = HCElement(members, classifier, children)
  end
  next_id = ndata + 1
  for row = 1:size(p.tree, 1) #each merge
    c1, c2 = p.tree[row, :]
    members = vcat(V[c1].members, V[c2].members)
    Dl_ = sub(Dl, members)
    labels = map(x -> x in c1, Dl_.labels) #one vs one, c1=true, c2=false
    Dl_ = setlabels(Dl_, labels) #new Dl
    classifier = train(gb_params, Dl_) #find rule
    children = Dict{Bool, Int64}([true => c1, false => c2])
    V[next_id] = HCElement(members, classifier, children)
    next_id += 1
  end
  return HCRules(p.tree, V)
end

function check!{T}(results::Vector{CheckResult}, hcrules::HCRules,
                   index::Int64, Dl::DFSetLabeled{T})
  node = hcrules.rules[index]
  if isempty(node.children)
    results[index] = CheckResult()
    return
  end
  Dl_ = sub(Dl, node.members)
  c1 = node.children[true]
  c2 = node.children[false]
  truth = map(x -> x in c1, Dl_.labels)
  pred = classify(node.classifier, Dl_)
  matched = node.members[find(pred .== truth)] #indices into Dl
  mismatched = node.members[find(pred .!= truth)] #indices into Dl
  results[index] = CheckResult(matched, mismatched)
  println("index=$index, matched=$(length(matched)), mismatched=$(length(mismatched))")
  if length(mismatched) != 0
    warn("Not matched: merge_of=$(node.children), mismatched=$mismatched")
  end
  for (bool, child_index) in node.children
    check!(results, hcrules, child_index, Dl)
  end
end

function checker{T}(hcrules::HCRules, Dl::DFSetLabeled{T})
  root_index = length(hcrules.rules)
  results = Array(CheckResult, root_index)
  check!(results, hcrules, root_index, Dl)
  return results
end

start(fcrules::FCRules) = start(fcrules.rules)
next(fcrules::FCRules, s) = next(fcrules.rules, s)
done(fcrules::FCRules, s) = done(fcrules.rules, s)
length(fcrules::FCRules) = length(fcrules.rules)

end #module


