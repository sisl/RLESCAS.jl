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

export plot_pop_distr, plot_fitness, plot_fitness5, plot_pop_diversity, drawplot

using Gadfly, Reel
using DataFrames

const FPS = 5

function drawplot(outfile::AbstractString, p::Plot;
                  width=4inch, height=3inch)
  if endswith(outfile, ".pdf")
    draw(PDF(outfile, width, height), p)
  elseif endswith(outfile, ".png")
    draw(PNG(outfile, width, height), p)
  elseif endswith(outfile, ".svg")
    draw(SVG(outfile, width, height), p)
  elseif endswith(outfile, ".tex")
    draw(PGF(outfile, width, height), p)
  elseif endswith(outfile, ".ps")
    draw(PS(outfile, width, height), p)
  else
    error("drawplot: extension not recognized $(splitext(outfile)[2])")
  end
end

#FIXME: these need to groupby ID

function plot_pop_distr(log::DataFrame, outfile::ASCIIString="pop_distr.gif")
  n_iters = maximum(log[:iter])

  film = roll(fps=FPS, duration=n_iters / FPS) do t, dt
    i = Int64(round(t * FPS + 1))
    D = log[log[:iter] .== i,:]
    plot(D, x="bin_center", y="count", Geom.bar,
         Guide.xlabel("Fitness"), Guide.ylabel("Count"), Guide.title("Population Fitness Over Time"))
  end
  write(outfile, film)
end

function plot_fitness(log::DataFrame, outfile::ASCIIString="fitness.pdf")
  p = plot(log, x="iter", y="fitness", Geom.point, Geom.line)
  drawplot(outfile, p)
  return p
end

function plot_fitness5(log::DataFrame, outfile::ASCIIString="fitness5.pdf")
  N = 5
  layers = [layer(x="iter", y="fitness$i", Geom.point, Geom.line) for i = 1:N]
  p = plot(log, layers...)
  drawplot(outfile, p)
  return p
end

function plot_pop_diversity(log::DataFrame, outfile::ASCIIString="pop_diversity.pdf")
  p = plot(log, layer(x="iter", y="unique_fitness", Geom.point, Geom.line),
           layer(x="iter", y="unique_code", Geom.point, Geom.line))
  drawplot(outfile, p)
  return p
end

end #module
