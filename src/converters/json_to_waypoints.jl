# Author: Ritchie Lee, ritchie.lee@sv.cmu.edu
# Date: 04/06/2015
#
# According to file format specified in Matlab script
# written by Mykel Kochenderfer, mykel@stanford.edu
#
# This script converts a json file produced by RLES and converts it to a "waypoints" file
# of the following format.
#
#   WAYPOINTS FILE:
#   The waypoints file contains a set of encounters. Each encounter is
#   defined by a set of waypoints associated with a fixed number of
#   aircraft. The waypoints are positions in space according to a fixed,
#   global coordinate system. All distances are in feet. Time is specified
#   in seconds since the beginning of the encounter. The file is organized
#   as follows:
#
#   [Header]
#   uint32 (number of encounters)
#   uint32 (number of aircraft)
#       [Encounter 1]
#           [Initial positions]
#               [Aircraft 1]
#               double (north position in feet)
#               double (east position in feet)
#               double (altitude in feet)
#               ...
#               [Aircraft n]
#               double (north position in feet)
#               double (east position in feet)
#               double (altitude in feet)
#           [Updates]
#               [Aircraft 1]
#               uint16 (number of updates)
#                   [Update 1]
#                   double (time in seconds)
#                   double (north position in feet)
#                   double (east position in feet)
#                   double (altitude in feet)
#                   ...
#                   [Update m]
#                   double (time in seconds)
#                   double (north position in feet)
#                   double (east position in feet)
#                   double (altitude in feet)
#               ...
#               [Aircraft n]
#                   ...
#       ...
#       [Encounter k]

include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")
include("corr_aem_save_scripts.jl")

using JSON
using Base.Test

json_to_waypoints_batch{T<:String}(filenames::Vector{T}) = pmap(f -> json_to_waypoints(f), filenames)

function json_to_waypoints{T<:String}(filenames::Vector{T}; outfile::String = "waypoints.dat")

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
      encounters[j, i] = Dict{String, Array{Float64, 2}}()
      encounters[j, i]["initial"] = j2w_initial(d, j)
      encounters[j, i]["update"] = j2w_update(d, j)'
    end
  end

  save_waypoints(outfile, encounters, numupdatetype = Uint16)

  return encounters
end

function j2w_initial(d::Dict{String,Any}, aircraft_number::Int64)
  #d is the loaded json / encounter

  out = Array(Float64, 1, 3)

  getvar(var::String) = sv_simlog_tdata_vid(d, "wm", aircraft_number, var, [1])[1]  # for local convenience

  pos_north     = getvar("y")
  pos_east      = getvar("x")
  altitude      = getvar("z")

  out[1, :] = [pos_north, pos_east, altitude]

  return out
end

function j2w_update(d::Dict{String, Any}, aircraft_number::Int64)
  #d is the loaded json / encounter,

  t_end = length(sorted_times(d, "wm", aircraft_number))
  out = Array(Float64, t_end - 1, 4)

  for t = 2 : t_end #ignore init values
    getvar(var::String) = sv_simlog_tdata_vid(d, "wm", aircraft_number, var, [t])[1]  # for local convenience

    t_         = getvar("t")
    pos_north  = getvar("y")
    pos_east   = getvar("x")
    altitude   = getvar("z")

    out[t - 1, :] = Float64[t_, pos_north, pos_east, altitude]
  end

  return out
end

function json_to_waypoints(filename::String)
  json_to_waypoints([filename], outfile = string(getSaveFileRoot(filename), "_waypoints.dat"))
end
