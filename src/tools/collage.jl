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

module Collage

export collage, collage_compact

using Compat
import Compat.ASCIIString
using ..DefineSave
using ..Visualize
using ..Visualize.TikzUtils
using ..SaveHelpers
using RLESUtils, FileUtils

using TikzPictures
import PGFPlots
import PGFPlots: Plots, Axis, GroupPlot

"""
Make a collage out of the vertical profile plots of the first N json.gz files
Expects clusterdirs to be in cluster number order
"""
function collage{T<:AbstractString}(outfileroot::T, clusterdirs::Vector{T}, 
    ncols::Int64, nrows::Int64=1)

    td = TikzDocument()
    enc_ids = Int64[]
    N = nrows * ncols
    for (i, dir) in enumerate(clusterdirs)
        fs = readdirGZs(dir)
        NN = min(N, length(fs)) 
        fs = fs[1:NN] 
        g = GroupPlot(ncols, nrows, groupStyle="horizontal sep=0.5cm, vertical sep=0.5cm")
        empty!(enc_ids)
        for f in fs
            sav = trajLoad(f)
            ax = pgfplot_alt(sav)
            push!(g, ax)
            push!(enc_ids, sv_encounter_id(sav)[1])
        end
        for j = 1:N-NN #fill remaining with empty axis for scaling
            push!(g, Axis())
        end
        tp = PGFPlots.plot(g)
        use_geometry_package!(tp, landscape=true)
        use_aircraftshapes_package!(tp)
        @compat cap = "Cluster $i: encounters=$(join(string.(enc_ids),","))"
        push!(td, tp; caption=cap)
    end
    TikzPictures.save(TEX(outfileroot), td)
    wrap_tikzpicture!("$(outfileroot).tex", "\\resizebox{\\textwidth}{!}{%\n", "\n}")
    lualatex_compile("$(outfileroot).tex")
    td
end

"""
Make a collage out of the vertical profile plots of the first N json.gz files
compact version
"""
function collage_compact{T<:AbstractString}(outfileroot::T, clusterdirs::Vector{T}, 
    N::Int64)

    td = TikzDocument()
    nclusters = length(clusterdirs)
    g = GroupPlot(N, nclusters, groupStyle="horizontal sep=1.75cm, vertical sep=1.75cm")
    enc_ids = Int64[]
    caps = ASCIIString[] 
    for (i, dir) in enumerate(clusterdirs)
        fs = readdirGZs(dir)
        NN = min(N, length(fs)) 
        fs = fs[1:NN] 
        empty!(enc_ids)
        for f in fs
            sav = trajLoad(f)
            ax = pgfplot_alt(sav)
            push!(g, ax)
            push!(enc_ids, sv_encounter_id(sav)[1])
        end
        for j = 1:N-NN #fill remaining with empty axis for scaling
            push!(g, Axis())
        end
        @compat push!(caps, "(Cluster $i: encounters=$(join(string.(enc_ids),",")))")
    end
    tp = PGFPlots.plot(g)
    use_geometry_package!(tp, landscape=true)
    use_aircraftshapes_package!(tp)
    push!(td, tp)
    TikzPictures.save(TEX(outfileroot), td)
    wrap_tikzpicture!("$(outfileroot).tex", "\\resizebox{!}{0.95\\textheight}{%\n", "\n}")
    lualatex_compile("$(outfileroot).tex")

    #output encounter numbers to text file
    textfile("$(outfileroot).txt", caps...)
    td
end

end #module
