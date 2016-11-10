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
# This script converts a json file produced by RLES and converts it to a "scripts" file
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

module JSON_To_Scripted

export json_to_scripted

import Compat.ASCIIString

using ..DefineSave
using ..SaveHelpers

include("corr_aem_save_scripts.jl")

using JSON
using Base.Test

function json_to_scripted{T<:AbstractString}(filenames::Vector{T}; outfile::AbstractString = "scripted.dat")

  d = trajLoad(filenames[1]) #use the first one as a reference
  num_aircraft = sv_num_aircraft(d, "wm")
  num_encounters = length(filenames) #one encounter per json file
  encounters = Array(Dict{ASCIIString, Array{Float64, 2}}, num_aircraft, num_encounters)

  #encounter i
  for (i, file) in enumerate(filenames)
    d = trajLoad(file)

    #make sure all of them have the same number of aircraft
    @test num_aircraft == sv_num_aircraft(d, "wm")

    #aircraft j
    for j = 1 : num_aircraft
      encounters[j, i] = Dict{ASCIIString,Array{Float64, 2}}()
      encounters[j, i]["initial"] = j2s_initial(d, j)
      encounters[j, i]["update"] = j2s_update(d, j)'
    end
  end

  save_scripts(outfile, encounters, numupdatetype=UInt8)

  return encounters
end

function j2s_initial{T<:AbstractString}(d::Dict{T, Any}, aircraft_number::Int64)
  #d is the loaded json / encounter
  #j is aircraft number

  out = Array(Float64, 1, 8)

  getvar(var::AbstractString) = sv_simlog_data_vid(d, "initial", aircraft_number, var)  # for local convenience

  airspeed            = getvar("v")
  pos_north           = getvar("y")
  pos_east            = getvar("x")
  altitude            = getvar("z")
  heading             = getvar("psi")   |> deg2rad #to radians
  flight_path_angle   = getvar("theta") |> deg2rad #to radians
  roll_angle          = getvar("phi")   |> deg2rad #to radians
  airspeed_accel      = getvar("v_d")

  out[1, :] = [airspeed, pos_north, pos_east, altitude, heading, flight_path_angle,
              roll_angle, airspeed_accel]

  return out
end

function j2s_update{T<:AbstractString}(d::Dict{T, Any}, aircraft_number::Int64)
  #d is the loaded json / encounter,
  #j is aircraft number

  t_end = length(sorted_times(d, "response", aircraft_number))
  out = Array(Float64, t_end - 1, 4)

  for t = 2 : t_end #ignore init values
    getvar(var::AbstractString) = sv_simlog_tdata_vid(d, "response", aircraft_number, var, [t])[1] # for local convenience

    t_     = getvar("t")
    h_d    = getvar("h_d")
    psi_d  = getvar("psi_d") |> deg2rad #to radians
    v_d    = getvar("v_d")

    out[t - 1, :] = Float64[t_, h_d, psi_d, v_d]
  end

  return out
end

function json_to_scripted(filename::AbstractString)

  json_to_scripted([filename], outfile = string(getSaveFileRoot(filename), "_scripted.dat"))
end

end #module
