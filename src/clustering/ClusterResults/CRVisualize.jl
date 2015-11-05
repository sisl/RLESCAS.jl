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

module CRVisualize

export plot_to_file

include(Pkg.dir("RLESCAS/src/defines/define_save.jl")) #trajLoad
include(Pkg.dir("RLESCAS/src/helpers/save_helpers.jl")) #sv_*
include(Pkg.dir("RLESCAS/src/visualize/visualize.jl")) #pgfplotLog

using TikzPictures
using PGFPlots
using ClusterResults

function plot_to_file(result::ClusterResult; outfileroot::String="clustervis")
  labelset = unique(result.labels)
  for label in labelset
    td = TikzDocument()
    for (f, l) in filter(x -> x[2] == label, zip(result.names, result.labels))
      d = trajLoad(f)
      tps = pgfplotLog(d)
      cap = string(vis_runtype_caps(d, sv_run_type(d)),
                   vis_sim_caps(d),
                   vis_runinfo_caps(d))
      add_to_document!(td, tps, cap)
    end
    outfile = string(outfileroot, "_$(label).pdf")
    TikzPictures.save(PDF(outfile), td)
    outfile = string(outfileroot, "_$(label).tex")
    TikzPictures.save(TEX(outfile), td)
  end
end

end #module
