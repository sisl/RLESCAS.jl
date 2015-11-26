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

export CRParams, explain_clusters, checker, CheckResult, FCCheckResult, HCCheckResult, show_check
export FCParams, FCRules, HCParams, HCRules, HCElement, get_truth

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
  classifier::Union{GBClassifier,Void}
  children::Dict{Bool,Int64}
end
HCElement() = HCElement(Int64[], nothing, Dict{Bool,Int64}())

type HCRules
  ndata::Int64
  tree::Array{Int64,2} #as a merge matrix starting from 1, input data indexed as 1:length(Dl)
  rules::Vector{HCElement}
end
HCRules() = HCRules(0, Array(Int64, 0, 0), HCElement[])

type CheckResult
  matched::Vector{Int64} #indices into Dl
  mismatched::Vector{Int64} #indices into Dl
end
CheckResult() = CheckResult(Int64[], Int64[])

type FCCheckResult{T}
  result::Dict{T,CheckResult}
end

type HCCheckResult
  ndata::Int64
  result::Vector{CheckResult}
end

#explain flat clustering
function explain_clusters{T}(p::FCParams, gb_params::GBParams, Dl::DFSetLabeled{T})
  labelset = unique(Dl.labels) |> sort!
  classifiers = pmap(labelset) do l
    truth = map(x -> x == l, Dl.labels) #one vs others mapping
    Dl_ = setlabels(Dl, truth) #new Dl
    return train(gb_params, Dl_) #out=classifier
  end
  rules = Dict{T, GBClassifier}(labelset, classifiers)
  return FCRules(rules)
end

function checker{T}(fcrules::FCRules, Dl::DFSetLabeled{T})
  result = Dict{T,CheckResult}()
  for (label, classifier) in fcrules
    truth = map(l -> l == label, Dl.labels)
    pred = classify(classifier, Dl)
    matched = find(pred .== truth) #indices
    mismatched = find(pred .!= truth) #indices
    result[label] = CheckResult(matched, mismatched)
    println("label=$label, matched=$(length(matched)), mismatched=$(length(mismatched))")
    if length(mismatched) != 0
      warn("Not matched: label=$label, mismatched=$(Dl.names[mismatched])")
    end
  end
  return FCCheckResult(result)
end

function show_check{T}(fcrules::FCRules, Dl::DFSetLabeled{T}, label::T)
  classifier = fcrules.rules[label]
  pred = classify(classifier, Dl)
  truth = map(l -> l == label, Dl.labels)
  correct = pred .== truth
  D = DataFrame()
  D[:name] = Dl.names
  D[:pred] = pred
  D[:truth] = truth
  D[:correct] = correct
  return D
end

function explain_clusters{T}(p::HCParams, gb_params::GBParams, Dl::DFSetLabeled{T})
  @assert size(p.tree, 2) == 2 #should have exactly 2 columns for the clusters to be merged
  @assert all(p.tree .> 0) #should be 1-indexed
  ndata = length(Dl)
  first_merge = ndata + 1 #index in V
  last_merge = maximum(p.tree) + 1 #index in V
  num_merges = size(p.tree, 1)

  R = Array(HCElement, last_merge)
  for i = 1:ndata #init data into own clusters
    members = Int64[i]
    classifier = nothing
    children = Dict{Bool, Int64}()
    R[i] = HCElement(members, classifier, children)
  end
  i = first_merge
  #bottom up (agglomerative) construction
  for row = 1:num_merges #each merge
    c1, c2 = p.tree[row, :] #cluster indices in V
    members = vcat(R[c1].members, R[c2].members)
    children = Dict{Bool, Int64}([true => c1, false => c2])
    R[i] = HCElement(members, nothing, children) #set classifier to nothing for now
    i += 1
  end
  #this construction allows parallel train
  classifiers = pmap(first_merge:last_merge) do i
    @assert !isempty(R[i].children) #non-leafs, should never trip
    truth = get_truth(R, i)
    Dl_sub = sub(Dl, R[i].members)
    Dl_sub = setlabels(Dl_sub, truth) #new Dl with true/false labels
    classifier = train(gb_params, Dl_sub) #find rule
  end
  for (i, mi) = enumerate(first_merge:last_merge)
    R[mi].classifier = classifiers[i]
  end
  return HCRules(ndata, p.tree, R)
end

#for an HC element
function get_truth(rules::Vector{HCElement}, index::Int64)
  R, i = rules, index
  c1 = R[i].children[true]
  c1_members = R[c1].members
  c2 = R[i].children[false]
  c2_members = R[c2].members
  truth = map(R[i].members) do member #one vs one, c1=true, c2=false
    if member in c1_members
      return true
    elseif member in c2_members
      return false
    else
      error("Member not in children: $member")
    end
  end
  return truth
end

function show_check{T}(hcrules::HCRules, Dl::DFSetLabeled{T}, index::Int64)
  if index <= hcrules.ndata
    println("Not a merge node. index should be > ndata")
    return
  end
  R = hcrules.rules
  members = R[index].members
  classifier = R[index].classifier
  Dl_sub = sub(Dl, R[index].members)
  pred = classify(classifier, Dl_sub)
  truth = get_truth(hcrules.rules, index)
  correct = pred .== truth
  D = DataFrame()
  D[:name] = Dl.names[members]
  D[:pred] = pred
  D[:truth] = truth
  D[:correct] = correct
  return D
end

function checker{T}(hcrules::HCRules, Dl::DFSetLabeled{T})
  ndata = hcrules.ndata
  first_merge = ndata + 1
  last_merge = length(hcrules.rules)
  R = hcrules.rules
  result_singles = [CheckResult() for i = 1:ndata] #leafs
  result_merges = pmap(first_merge:last_merge) do i
    @assert !isempty(R[i].children) #non-leafs, should never trip
    truth = get_truth(R, i)
    Dl_sub = sub(Dl, R[i].members)
    pred = classify(R[i].classifier, Dl_sub)
    matched = R[i].members[find(pred .== truth)] #indices into Dl
    mismatched = R[i].members[find(pred .!= truth)] #indices into Dl
    println("index=$i, matched=$(length(matched)), mismatched=$(length(mismatched))")
    if length(mismatched) != 0
      warn("mismatched=$mismatched")
    end
    return CheckResult(matched, mismatched)
  end
  result = vcat(result_singles, result_merges)
  return HCCheckResult(ndata, result)
end

start(fcrules::FCRules) = start(fcrules.rules)
next(fcrules::FCRules, s) = next(fcrules.rules, s)
done(fcrules::FCRules, s) = done(fcrules.rules, s)
length(fcrules::FCRules) = length(fcrules.rules)

end #module


