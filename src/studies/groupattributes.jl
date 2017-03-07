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

include("define_save.jl") #trajLoad

function groupattributes{T<:AbstractString}(files::Vector{T}, getlabel::Function, getx::Function, gety::Function)

  outdict = Dict{ASCIIString, Vector{(Float64, Vector{Float64})}}()

  M = Array(Any, length(files), 3) #number of files by L,x,y

  for (i, f) in enumerate(files)

    d = trajLoad(f)
    M[i, :] = [getlabel(d), getx(d), gety(d)] #each row is L, x, y
  end

  for (L, L_inds) in groupbycol(M, 1)

    Mx = M[L_inds, :]

    xyvecs = map(groupbycol(Mx, 2)) do tup #vector of (x, yvec)
      x, xinds = tup

      return (Float64(x), Float64(Mx[xinds, 3])) #convert to float for plotting
    end

    sort!(xyvecs, by = v -> v[1]) #sort the x's of easier plotting

    outdict[L] = xyvecs
  end

  return outdict
end

function groupbycol(M::Array{Any, 2}, col::Int64)
  #Looks at all the entries in column 'col' of M.  For each unique entry, return a list of row indices

  labels = unique(M[:, col])
  inds = map(l -> find(x -> x == l, M[:, col]), labels)

  return zip(labels, inds)
end
