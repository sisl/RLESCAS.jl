# Author: Ritchie Lee, ritchie.lee@sv.cmu.edu
# Date: 04/06/2015
#
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

include("../defines/define_save.jl")
include("corr_aem_save_scripts.jl")

using JSON
using Base.Test

json_to_scripts_batch{T<:String}(filenames::Vector{T}) = map(json_to_scripts, filenames)

function json_to_scripts{T<:String}(filenames::Vector{T}; outfile::String = "scripts.dat")

  d = trajLoad(filenames[1]) #use the first one as a reference
  num_aircraft = sv_num_aircraft(d, "wm")
  num_encounters = length(filenames) #one encounter per json file
  encounters = Array(Dict{String, Array{Float64, 2}}, num_aircraft, num_encounters)

  #encounter i
  for (i, file) in enumerate(filenames)
    d = trajLoad(file)

    #make sure all of them have the same number of aircraft
    @test num_aircraft == sv_num_aircraft(d, "wm")

    #aircraft j
    for j = 1 : num_aircraft
      encounters[j,i] = Dict{String,Array{Float64, 2}}()
      encounters[j,i]["initial"] = j2s_initial(d, j)
      encounters[j,i]["update"] = j2s_update(d, j)'
    end
  end

  save_scripts(outfile, encounters, numupdatetype = Uint8)

  return encounters
end

function j2s_initial(d::Dict{String, Any}, aircraft_number::Int64)
  #d is the loaded json / encounter
  #j is aircraft number

  out = Array(Float64, 1, 8)

  getvar(var::String) = sv_simlog_data(d, "initial", aircraft_number, var)  # for local convenience

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

function j2s_update(d::Dict{String, Any}, aircraft_number::Int64)
  #d is the loaded json / encounter,
  #j is aircraft number

  t_end = length(sorted_times(d, "response", aircraft_number))
  out = Array(Float64, t_end - 1, 4)

  for t = 2 : t_end #ignore init values
    getvar(var::String) = sv_simlog_tdata(d, "response", aircraft_number, t, var) # for local convenience

    t_     = getvar("t")
    h_d    = getvar("h_d")
    psi_d  = getvar("psi_d") |> deg2rad #to radians
    v_d    = getvar("v_d")

    out[t - 1, :] = Float64[t_, h_d, psi_d, v_d]
  end

  return out
end

function json_to_scripts(filename::String)

  json_to_scripts([filename], outfile = string(getSaveFileRoot(filename), "_scripts.dat"))
end
