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

module Label270_To_Text

export label270_to_text

using ..DefineSave
using ..SaveHelpers

label270_to_text{T<:AbstractString}(infiles::Vector{T}) = pmap(label270_to_text, infiles)

function label270_to_text(infile::AbstractString)
  d = trajLoad(infile)

  tind = sv_lookup_id(d, "wm", "t")
  lind = sv_lookup_id(d, "ra", "label270")

  outfileroot = getSaveFileRoot(infile)
  outfile = string(outfileroot,"_label270.txt")
  f = open(outfile,"w")

  for i = 1:sv_num_aircraft(d, "ra")
    println(f, "Aircraft $i")

    label_tm1 = ""
    times = sv_simlog_tdata_vid(d, "wm", i, tind)
    labels = sv_simlog_tdata_vid(d, "ra", i, lind)
    for (t, label_t) in zip(times, labels)

      if label_t != label_tm1 #only output on change
        println(f, "$(t) \t\t $(label_t)")
      end

      label_tm1 = label_t
    end

    println(f, "\n\n")
  end

  close(f)
end

end #module
