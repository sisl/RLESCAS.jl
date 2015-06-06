# Author: Youngjun Kim, youngjun@stanford.edu
# Date: 08/19/2014
#
# Originally written in MATLAB by Mykel Kochenderfer, mykel@stanford.edu
# Converted by Youngjun Kim, youngjun@stanford.edu

#   SAVE_SCRIPTS(FILENAME,SCRIPTS) saves a structure holding the encounter
#   scripts stored to the specified file.
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
#
#   SCRIPTS STRUCTURE:
#   The scripts structure is an m x n structure matrix, where m is the
#   number of aircraft and n is the number of encounters. This structure
#   matrix has two fields: initial and update. The initial field is an 8
#   element array specifying the airspeed, north position, east position,
#   altitude, heading, flight path angle, roll angle, and airspeed
#   acceleration. The update field is a 4 x n matrix, where n is the number
#   of updates. The rows correspond to the time, vertical rate, turn rate
#   and airspeed acceleration.

# Inputs:
#       filename: name of output file
#
#       encounters: structure of encounters to save to file specified by
#       "filename".  For a guide to the format of this structure, see
#       the help documentation in load_scripts.m.
#
#       varargin: parameter/value pairs
#
#           +   parameter: numupdatetype
#
#               value (character string): data type of "num_update"
#               variable: the number of updates scripted for some aircraft
#               in some encounter (default is 'uint32')
#
#           +   parameter: append
#
#               value (logical): set to true to append encounters to the
#               end of the file specified by "filename".  Set to false
#               (default) to write a new file with the name specified by
#               "filename".
#
#           +   parameter: floattype
#
#               value (character string): data type of encounter initial
#               conditions and updates (default is 'double')


function save_encounters(filename, encounters; numupdatetype = Uint32, append = false, floattype = Float64)

    num_encounters::Uint32 = size(encounters, 2)
    num_ac = size(encounters, 1)

    if append
        if isreadable(filename) == false
            fio = open(filename, "w")

            write(fio, uint32(num_encounters))
            write(fio, uint32(num_ac))
        else
            fio = open(filename, "a+")
            seekstart(fio)

            file_num_encounters = read(fio, Uint32)
            file_num_ac = read(fio, Uint32)

            if file_num_ac != num_ac
                error("Must have the same number of aircraft when appending encounter files")
            end

            seekstart(fio)
            write(fio, uint32(file_num_encounters + num_encounters))

            seekend(fio)
        end
    else
        fio = open(filename, "w")

        write(fio, uint32(num_encounters))
        write(fio, uint32(num_ac))
    end

    for i = 1:num_encounters
        for j = 1:num_ac
            write(fio, convert(Array{floattype}, encounters[j, i]["initial"]))
        end

        for j = 1:num_ac
            num_update = size(encounters[j, i]["update"], 2)

            write(fio, convert(numupdatetype, num_update))
            write(fio, convert(Array{floattype}, (encounters[j, i]["update"])))
        end
    end

    close(fio)
end

function save_scripts(filename, scripts; numupdatetype = Uint8, append = false, floattype = Float64)

    save_encounters(filename, scripts; numupdatetype = numupdatetype, append = append, floattype = floattype)
end

function save_waypoints(filename, scripts; numupdatetype = Uint16, append = false, floattype = Float64)

    save_encounters(filename, scripts; numupdatetype = numupdatetype, append = append, floattype = floattype)
end

if false
    save_scripts("encounters.dat", scripts; append = false)
end


