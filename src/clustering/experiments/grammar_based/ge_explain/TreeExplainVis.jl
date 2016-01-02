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

module TreeExplainVis

export drawplot, plot_pop_distr, plot_fitness, plot_fitness5, plot_pop_diversity, plot_itertime

using DataFrames
using Plots

gadfly()
dataframes()

function drawplot(outfile::AbstractString, p::Plot)
  if endswith(outfile, ".pdf")
    Plots.pdf(p, outfile)
  elseif endswith(outfile, ".png")
    Plots.png(p, outfile)
  elseif endswith(outfile, ".svg")
    Plots.svg(p, outfile)
  elseif endswith(outfile, ".tex")
    Plots.tex(p, outfile)
  elseif endswith(outfile, ".ps")
    Plots.ps(p, outfile)
  else
    error("drawplot: extension not recognized $(splitext(outfile)[2])")
  end
end

function writefilm(file::AbstractString, film::Animation, fps::Int64; remove_destination::Bool=true)
  ext = splitext(file)[2]
  tmpfile = splitext(basename(tempname()))[1] * ext #temp name, current directory, same ext as file
  gif(film, tmpfile, fps=fps)
  mv(tmpfile, file, remove_destination=remove_destination) #workaround for Reel not working for long filenames
end

function plot_pop_distr(log::DataFrame, outfile::ASCIIString="pop_distr.gif"; fps::Int64=5)
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    id = D[:decision_id][1]
    n_iters = maximum(D[:iter])

    #counts
    film1 = Animation()
    for i = 1:n_iters
      D1 = D[D[:iter] .== i, [:bin_center, :count]]
      p = plot(D1, :bin_center, :count, linetype=:bar,
           xlabel="Fitness", ylabel="Count", title="Population Fitness, Generation=$i");
      frame(film1, p)
    end
    writefilm("$(fileroot)_$(id)_counts$ext", film1, fps)

    #unique fitness
    film2 = Animation()
    for i = 1:n_iters
      D1 = D[D[:iter] .== i, [:bin_center, :unique_fitness]]
      p = plot(D1, :bin_center, :unique_fitness, linetype=:bar,
           xlabel="Fitness", ylabel="Number of Unique Fitness", title="Population Unique Fitness, Generation=$i");
      frame(film2, p)
    end
    writefilm("$(fileroot)_$(id)_uniqfitness$ext", film2, fps)

    #unique code
    film3 = Animation()
    for i = 1:n_iters
      D1 = D[D[:iter] .== i, [:bin_center, :unique_code]]
      p = plot(D1, :bin_center, :unique_code, linetype=:bar,
           xlabel="Fitness", ylabel="Number of Unique Code", title="Population Unique Code, Generation=$i");
      frame(film3, p)
    end
    writefilm("$(fileroot)_$(id)_uniqcode$ext", film3, fps)
  end
end

function plot_fitness(log::DataFrame, outfile::ASCIIString="fitness.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    id = D[:decision_id][1]
    p = plot(D, :iter, :fitness, marker=:rect);
    push!(plotvec, p)
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

function plot_fitness5(log::DataFrame, outfile::ASCIIString="fitness5.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    id = D[:decision_id][1]
    p = plot(D, :iter, :fitness, group=:position, marker=:rect);
    push!(plotvec, p)
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

function plot_pop_diversity(log::DataFrame, outfile::ASCIIString="pop_diversity.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    id = D[:decision_id][1]
    D1 = DataFrame(x=D[:iter], y=D[:unique_fitness], label="num_unique_fitness")
    D2 = DataFrame(x=D[:iter], y=D[:unique_code], label="num_unique_code")
    p = plot(vcat(D1, D2), :x, :y, group=:label, marker=:rect);
    push!(plotvec, p)
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

function plot_itertime(log::DataFrame, outfile::ASCIIString="itertime.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    id = D[:decision_id][1]
    p = plot(D, :iter, :iteration_time_s, marker=:rect);
    push!(plotvec, p)
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

end #module
