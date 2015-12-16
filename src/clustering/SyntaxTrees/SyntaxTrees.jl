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

module SyntaxTrees

export SyntaxTree, STNode, parse_ex, visit!

type STNode
  cmd::ASCIIString
  args::Vector{STNode}
end
STNode(cmd::AbstractString) = STNode(cmd, STNode[])

type SyntaxTree
  root::STNode
end
SyntaxTree(s::AbstractString) = parse_ex(s)

function parse_ex(s::AbstractString)
  ex = parse(s)
  root = parse_ex(ex)
  return SyntaxTree(root)
end

parse_ex(val) = STNode("$val")
parse_ex(ex::Expr) = parse_ex(Val{ex.head}, ex.args)

parse_ex(V::Type{Val{:call}}, args) = parse_ex1(V, args)
parse_ex(V::Type{Val{:ref}}, args) = parse_ex1(V, args)
parse_ex(V::Type{Val{:comparison}}, args) = parse_ex2(V, args)

#e.g., ||, &&
parse_ex{T}(V::Type{Val{T}}, args) = parse_ex0(V, args)

#cmd is 1st argument, others are args
function parse_ex0{T}(::Type{Val{T}}, args)
  args1 = map(parse_ex, args)
  return STNode("$T", args1)
end

#cmd is 1st argument, others are args
function parse_ex1{T}(::Type{Val{T}}, args)
  args1 = map(parse_ex, args[2:end])
  return STNode("$(args[1])", args1)
end

#cmd is 2nd argument, others are arg
function parse_ex2{T}(::Type{Val{T}}, args)
  args1 = map(parse_ex, args[[1, 3]])
  return STNode("$(args[2])", args1)
end

function visit!(tree::SyntaxTree, f::Function)
  tree.root = visit(tree.root, f)
end

function visit(node::STNode, f::Function)
  node = f(node)
  for i in eachindex(node.args)
    node.args[i] = visit(node.args[i], f)
  end
  return node
end

end #module
