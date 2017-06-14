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

module Fill_To_Max_Time

export fill_to_max_time

using AdaptiveStressTesting: ASTAction
using RLESUtils, Obj2Dict, RNGWrapper, Loggers, Obj2DataFrames

using ..DefineSave
using ..SaveHelpers

function fill_to_max_time(filename::AbstractString)
    d = trajLoad(filename)

    # disable ending on nmac
    sim_params = get_sim_params(d) 
    sim_params.end_on_nmac = false
    set_sim_params!(d, sim_params)

    action_seq = get_action_seq(d)
    ast_params = get_ast_params(d)
    rsg_length = ast_params.rsg_length

    max_steps = sim_params.max_steps
    steps_to_append = max_steps - length(action_seq)  #determine number of missing steps

    # steps_to_append > 0 check is automatically handled by comprehension
    seed = steps_to_append #arbitrarily use this as a seed
    actions_to_append = ASTAction[ ASTAction(rsg_length, seed) for t = 1:steps_to_append ] #append hash of t
    action_seq = vcat(action_seq, actions_to_append)

    set_action_seq!(d, action_seq)
    outfilename = trajSave(string(getSaveFileRoot(filename), "_filled"), d)
    println("File: ", filename, "; Steps appended: ", steps_to_append)

    outfilename
end

end #module
