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


# According to file format specified in Matlab script
# written by Mykel Kochenderfer, mykel@stanford.edu
#
# This script converts a log file produced by RLES and converts it to a "scripts" file
# of the following format:
#
#   SCRIPTS FILE:
#   The scripts file contains a set of scripted encounters. Each
#   encounter is defined by a set of encounter scripts associated with a
#   fixed number of aircraft. The file is organized as follows:
#
#   [Header]
#   uint32 (number of encounters)
#   uint32 (number of aircraft)
#       [Encounter 1]
#           [Initial]
#               [Aircraft 1]
#               double (initial airspeed in ft/s)
#               double (initial north position in ft)
#               double (initial east position in ft)
#               double (initial altitude in ft)
#               double (initial heading angle in radians)
#               double (initial flight path angle in radians)
#               double (initial roll angle in radians)
#               double (initial airspeed acceleration in ft/s^2)
#               ...
#               [Aircraft n]
#               double (initial airspeed in ft/s)
#               double (initial north position in ft)
#               double (initial east position in ft)
#               double (initial altitude in ft)
#               double (initial heading angle in radians)
#               double (initial flight path angle in radians)
#               double (initial roll angle in radians)
#               double (initial airspeed acceleration in ft/s^2)
#           [Updates]
#               [Aircraft 1]
#               uint8 (number of updates)
#                   [Update 1]
#                   double (time in s)
#                   double (commanded vertical rate in ft/s)
#                   double (commanded turn rate in rad/s)
#                   double (commanded airspeed acceleration in ft/s^2)
#                   ...
#                   [Update m]
#                   double (time in s)
#                   double (commanded vertical rate in ft/s)
#                   double (commanded turn rate in rad/s)
#                   double (commanded airspeed acceleration in ft/s^2)
#               ...
#               [Aircraft n]
#                   ...
#       ...
#       [Encounter k]
#           ...

module Log_To_Scripted

export log_to_scripted

using ..DefineSave
using ..SaveHelpers

include("corr_aem_save_scripts.jl")

using JSON
using DataFrames

function log_to_scripted{T<:AbstractString}(filenames::Vector{T}; 
    outfile::AbstractString = "scripted.dat")

    d = trajLoad(filenames[1]) #use the first one as a reference
    num_aircraft = get_num_aircraft(d)
    num_encounters = length(filenames) #one encounter per log file
    encounters = Array(Dict{String, Array{Float64, 2}}, num_aircraft, num_encounters)

    #encounter i
    for (i, file) in enumerate(filenames)
        d = trajLoad(file)

        #make sure all of them have the same number of aircraft
        @assert num_aircraft == get_num_aircraft(d)

        #aircraft j
        for j = 1:num_aircraft
            encounters[j, i] = Dict{String,Array{Float64, 2}}()
            encounters[j, i]["initial"] = j2s_initial(d, j)
            encounters[j, i]["update"] = j2s_update(d, j)'
        end
    end
    save_scripts(outfile, encounters, numupdatetype=UInt8)
    encounters
end

function j2s_initial(d::TrajLog, aircraft_number::Int64)
    #d is the loaded encounter
    #j is aircraft number

    out = Array(Float64, 1, 8)
    initial = get_log(d, "Initial", aircraft_number)
    airspeed            = initial[1, :v] 
    pos_north           = initial[1, :y] 
    pos_east            = initial[1, :x] 
    altitude            = initial[1, :z] 
    heading             = initial[1, :psi]   |> deg2rad #to radians
    flight_path_angle   = initial[1, :theta] |> deg2rad #to radians
    roll_angle          = initial[1, :phi]   |> deg2rad #to radians
    airspeed_accel      = initial[1, :v_d]

    out[1, :] = [airspeed, pos_north, pos_east, altitude, heading, flight_path_angle,
              roll_angle, airspeed_accel]
    out
end

function j2s_update(d::TrajLog, aircraft_number::Int64)
    #d is the loaded encounter,
    pr = get_log(d, "Response", aircraft_number)
    t_end = nrow(pr) 
    out = Array(Float64, t_end-1, 4)
    for t = 2:t_end #ignore init values
        t_     = pr[t, :t]
        h_d    = pr[t, :h_d]
        psi_d  = pr[t, :psi_d] |> deg2rad #to radians
        v_d    = pr[t, :v_d]
        out[t-1, :] = Float64[t_, h_d, psi_d, v_d]
    end
    out
end

function log_to_scripted(filename::AbstractString)
  log_to_scripted([filename], outfile = string(getSaveFileRoot(filename), "_scripted.dat"))
end

end #module
