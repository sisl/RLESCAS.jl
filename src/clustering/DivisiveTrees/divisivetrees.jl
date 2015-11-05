module DivisiveTrees

export DataSet, DTParams, DivisiveTree, DTNode, build_tree, classify, entropy, gain, gains, maxgain

type DataSet{T}
  records::Vector{T}
end

type DTParams
  get_rule::Function #get_rule(S, records)
  predict::Function #predict(split_rule, S, records)
  stopcriterion::Function
  nclusters::Int64
end
DTParams(get_rule::Function, predict::Function, stopcriterion::Function) = DTParams(get_rule, predict, stopcriterion, 0)

type DTNode
  split_rule::Any #splits into true/false
  members::Vector{Int64} #index into input
  children::Dict{Any, DTNode} #key=split result, value=child node
  label::Any #nothing for non-leaf, otherwise the predicted class label
  depth::Int64 #depth into tree (root at 0)
end
DTNode() = DTNode(nothing, Int64[], Dict{Bool, DTNode}(), nothing, 0)

type DivisiveTree
  root::DTNode
end

#Attributes is records (rows) by attribute (cols)
function build_tree(S::DataSet, p::DTParams)
  allrecords = [1:length(S.records)]
  root = DTNode()
  process_node!(root, S, allrecords, p)
  return DivisiveTree(root)
end

function process_node!(node::DTNode, S::DataSet, records::Vector{Int64}, p::DTParams)
  node.members = deepcopy(records)
  empty!(node.children)
  node.split_rule = p.get_rule(S, records)
  split_result = p.predict(node.split_rule, S, records)
  splitset = unique(split_result)
  #all labels are the same or user stopping
  if length(splitset) == 1 ||
      p.stopcriterion(split_result, node.depth, p.nclusters)
    node.split_rule = nothing
    node.label = nextlabel!(p) #no more splits
  else
    node.label = nothing #not a leaf
    for val in splitset
      node.children[val] = child = DTNode()
      child.depth = node.depth + 1
      ids = find(x -> x == val, split_result)
      childrecords = records[ids]
      process_node!(child, S, childrecords, p) #recurse on child
    end
  end
  return
end

function classify(node::DTNode, record::Any, rules::Vector{Any})
  if node.label != nothing
    return (node.label, rules)
  end
  push!(rules, node.split_rule)
  split_result = p.predict(node.split_rule, record)
  child = node.children[split_result]
  return classify(child, record)
end
function classify(dtree::DivisiveTree, record::Any)
  rules = Array(Any, 0)
  return classify(dtree.root, record, rules)
end

nextlabel!(p::DTParams) = p.nclusters += 1

end #module
