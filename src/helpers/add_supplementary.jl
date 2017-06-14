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

module AddSupplementary

export add_label270, add_supplementary

using ..DefineSave
using ..SaveHelpers
using ..Label270
using DataFrames

add_label270{T<:AbstractString}(files::Vector{T}) = map(add_label270, files)
function add_label270(file::AbstractString)
    d = trajLoad(file)
    num_aircraft = get_num_aircraft(d)
    for i = 1:num_aircraft
        df = d["CAS_$i"]
        t_end = nrow(df) 
        prev_label_code = 0 #code at previous change
        code_tm1 = 0 #code at t-1
        labels = String[]
        label_shorts = String[]
        for t = 1:t_end
            code = get_code(df[t, :ownOutput_cc], df[t, :ownOutput_vc], df[t, :ownOutput_ua], 
                df[t, :ownOutput_da])
            crossing = df[t, :ownOutput_crossing]
            #prev_code is previous different code
            if code != code_tm1
                prev_label_code = code_tm1
            end
            label = get_textual_label(code, prev_label_code, crossing, true)
            push!(labels, label) #append to data vector
            label_short = get_textual_label(code, prev_label_code, crossing, false)
            push!(label_shorts, label_short) #append to data vector
            code_tm1 = code
        end
        df[:label270] = labels
        df[:label270_short] = label_shorts
    end
    trajSave(getSaveFileRoot(file), d)
end

add_supplementary{T<:AbstractString}(files::Vector{T}) = map(add_supplementary, files)
function add_supplementary(file::AbstractString)
  add_label270(file)
end

end #module
