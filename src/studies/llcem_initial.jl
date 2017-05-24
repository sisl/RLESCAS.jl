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

using DataFrames
using Datasets
using RLESUtils, PGFPlotUtils
using TikzPictures

const COLNAMEMAP = [:id=>:id, :A=>:A, :L=>:L, :_chi=>:chi, :_beta=>:beta, 
    :C_1=>:C1, :C_2=>:C2,:v_1=>:v1, :v_2=>:v2, :_dot_v_1=>:v1d, :_dot_v_2=>:v2d, 
    :_dot_h_1=>:h1d, :_dot_h_2=>:h2d, :_dot_psi_1=>:psi1d, :_dot_psi_2=>:psi2d, 
    :hmd=>:hmd, :vmd=>:vmd]

function initial_to_DataFrame(init_file::AbstractString)
    D = readtable(init_file; separator=' ')
    for (from,to) in COLNAMEMAP
        if from != to
            rename!(D, from, to) 
        end
    end
    D
end

"""
Repairs the id number so that it matches the row number.  This is useful for fixing
the id numbers after, for example, manually replacing the first encounter with the 
standard header.
"""
function repair_ids(init_file::AbstractString; skipfirst::Bool=true, delim=' ')
    toks = splitext(init_file)
    outfile = toks[1] * "_repaired" * toks[2]
    fin = open(init_file, "r")
    fout = open(outfile, "w")
    i = 1
    if skipfirst #header
        line = readline(fin)
        print(fout, line)
    end
    for line in readlines(fin)
        toks = split(line, delim)
        toks[1] = "$i"
        join(fout, toks, delim)
        i += 1
    end
    close(fin)
    close(fout)
end

function llcem_initial_study(init_file::AbstractString, data_name::AbstractString;
    outfileroot::AbstractString="llcem_initial", format::Symbol=:TEXPDF)
    m = load_meta(data_name)
    nmac_ids = find(m[:nmac])
    init = initial_to_DataFrame(init_file)
    td = histogram_all_cols_sbs(init[nmac_ids,:], init; 
        discretization=:sqrt,
        datanames=["nmacs", "all"])
    plot_tikz(outfileroot, td, format)
end

