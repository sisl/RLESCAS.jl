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

module DefineLog

export addObservers

using AdaptiveStressTesting
using SISLES
using SISLES: Encounter, EncounterDBN, WorldModel, Sensor, CollisionAvoidanceSystem, 
    DynamicModel, PilotResponse, GenerativeModel
using RLESUtils, Loggers

using ..DefineSave

const ENABLE_ROUNDING = true
const ROUND_NDECIMALS = 9

function addObservers(sim::ACASX_GM)
    clearObservers!(sim)
    log = TaggedDFLogger()
    #separate folders for each aircraft.  logs can be different.  e.g. 2 different CAS 
    for i = 1:sim.params.num_aircraft
        #data
        add_folder!(log, "CAS_info_$i", cas_info_types(sim.cas[i]),  cas_info_names(sim.cas[i]))
        add_folder!(log, "Initial_$i", initial_types(sim.em),  initial_names(sim.em))
        add_folder!(log, "Command_$i", command_types(sim.em.output_commands[i]), 
            command_names(sim.em.output_commands[i]))
        add_folder!(log, "Sensor_$i", sensor_types(sim.sr[i]),  sensor_names(sim.sr[i]))
        add_folder!(log, "CAS_$i", cas_types(sim.cas[i]),  cas_names(sim.cas[i]))
        add_folder!(log, "Response_$i", response_types(sim.pr[i]),  response_names(sim.pr[i]))
        add_folder!(log, "Dynamics_$i", dynamics_types(sim.dm[i]),  dynamics_names(sim.dm[i]))
        add_folder!(log, "WorldModel_$i", worldmodel_types(sim.wm),  worldmodel_names(sim.wm))

        #units
        names = cas_info_names(sim.cas[i])
        units = cas_info_units(sim.cas[i])
        add_folder!(log, "CAS_info_units_$i", fill(String, length(units)), names)
        push!(log, "CAS_info_units_$i", units)
        names = initial_names(sim.em)
        units = initial_units(sim.em)
        add_folder!(log, "Initial_units_$i", fill(String, length(units)), names)
        push!(log, "Initial_units_$i", units)
        names = command_names(sim.em.output_commands[i])
        units = command_units(sim.em.output_commands[i])
        add_folder!(log, "Command_units_$i", fill(String, length(units)), names)
        push!(log, "Command_units_$i", units)
        names = sensor_names(sim.sr[i])
        units = sensor_units(sim.sr[i])
        add_folder!(log, "Sensor_units_$i", fill(String, length(units)), names)
        push!(log, "Sensor_units_$i", units)
        names = cas_names(sim.cas[i])
        units = cas_units(sim.cas[i])
        add_folder!(log, "CAS_units_$i", fill(String, length(units)), names)
        push!(log, "CAS_units_$i", units)
        names = response_names(sim.pr[i])
        units = response_units(sim.pr[i])
        add_folder!(log, "Response_units_$i", fill(String, length(units)), names)
        push!(log, "Response_units_$i", units)
        names = dynamics_names(sim.dm[i])
        units = dynamics_units(sim.dm[i])
        add_folder!(log, "Dynamics_units_$i", fill(String, length(units)), names)
        push!(log, "Dynamics_units_$i", units)
        names = worldmodel_names(sim.wm)
        units = worldmodel_units(sim.wm)
        add_folder!(log, "WorldModel_units_$i", fill(String, length(units)), names)
        push!(log, "WorldModel_units_$i", units)
    end
    #data
    add_folder!(log, "logProb", logprob_types(), logprob_names()) 
    add_folder!(log, "run_info", run_info_types(), run_info_names()) 

    #units
    names = logprob_names()
    units = logprob_units()
    add_folder!(log, "logProb_units", fill(String, length(units)), names)
    push!(log, "logProb_units", units)
    names = run_info_names()
    units = run_info_units()
    add_folder!(log, "run_info_units", fill(String, length(units)), names)
    push!(log, "run_info_units", units)

    addObserver(sim, "CAS_info",   x->log_cas_info!(log, x))
    addObserver(sim, "Initial",    x->log_initial!(log, x))
    addObserver(sim, "Command",    x->log_command!(log, x))
    addObserver(sim, "Sensor",     x->log_sensor!(log, x))
    addObserver(sim, "CAS",        x->log_cas!(log, x))
    addObserver(sim, "Response",   x->log_response!(log, x))
    addObserver(sim, "Dynamics",   x->log_adm!(log, x))
    addObserver(sim, "WorldModel", x->log_wm!(log, x))
    addObserver(sim, "logProb",   x->log_logProb!(log, x))
    addObserver(sim, "run_info",   x->log_run_info!(log, x))

    TrajLog(log)
end

function log_cas_info!(log::TaggedDFLogger, args)
    #[CAS version]
    i, cas = args 
    push!(log, "CAS_info_$i", cas_info_data(cas))
end

cas_info_names(cas::Union{ACASX_CCAS,ACASX_ADD}) = String["version"] 
cas_info_types(cas::Union{ACASX_CCAS,ACASX_ADD}) = [String] 
cas_info_units(cas::Union{ACASX_CCAS,ACASX_ADD}) = String["n/a"]
cas_info_data(cas::Union{ACASX_CCAS,ACASX_ADD}) = Any[cas.version]

function log_initial!(log::TaggedDFLogger, args)
    #[aircraft_number, time_index, initial]
    i, t, aem = args
    @assert t == 0
    push!(log, "Initial_$i", initial_data(i, aem))
end

initial_names(aem::CorrAEMDBN) = String["v", "x", "y", "z", "psi", "theta", "phi", "v_d"]
initial_types(aem::CorrAEMDBN) = [Float64,Float64,Float64,Float64, Float64,Float64, 
    Float64,Float64]
initial_units(aem::CorrAEMDBN) = String["ft/s", "ft", "ft", "ft", "deg", "deg", "deg", "ft/s^2"]

function initial_data(i, aem::CorrAEMDBN)
    # initial
    # airspeed, ft/s, double
    # north position, ft, double
    # east position, ft, double
    # altitude, ft, double
    # heading angle, degrees, double
    # flight path angle, degrees, double
    # roll angle, degrees, double
    # airspeed acceleration, ft/s^2, double

    t, x, y, h, v, psi = aem.aem.dynamic_states[i, 1, :]
    t_n, x_n, y_n, h_n, v_n, psi_n, = aem.aem.dynamic_states[i, 2, :]

    t, v_d, h_d, psi_d = aem.aem.states[i, 1, :]

    theta = atand((h_n - h) / norm(x_n - x, y_n - y)) |> to_plusminus_180
    phi = 0.0

    return round_floats(Any[v, x, y, h, psi, theta, phi, v_d], ROUND_NDECIMALS,
                      enable = ENABLE_ROUNDING)
end

initial_names(aem::Union{StarDBN,SideOnDBN}) = String["v", "x", "y", "z", "psi", "theta", "phi", "v_d"]
initial_types(aem::Union{StarDBN,SideOnDBN}) = [Float64,Float64,Float64,Float64,Float64,Float64,
    Float64,Float64]
initial_units(aem::Union{StarDBN,SideOnDBN}) = String["ft/s", "ft", "ft", "ft", "deg", "deg", "deg", "ft/s^2"]

function initial(i, aem::Union{StarDBN,SideOnDBN})
    # initial
    # airspeed, ft/s, double
    # north position, ft, double
    # east position, ft, double
    # altitude, ft, double
    # heading angle, degrees, double
    # flight path angle, degrees, double
    # roll angle, degrees, double
    # airspeed acceleration, ft/s^2, double

    is = aem.initial_states[i]
    t, x, y, h, v, psi = is.t, is.x, is.y, is.h, is.v, is.psi

    L, v_d, h_d, psi_d = aem.initial_commands[i]

    theta = atand(h_d / v)
    phi = 0.0

    return round_floats(Any[v, x, y, h, psi, theta, phi, v_d], 
        ROUND_NDECIMALS, enable=ENABLE_ROUNDING)
end

function log_command!(log::TaggedDFLogger, args)
    #[aircraft_number, time_index, command]
    i, t, command = args
    push!(log, "Command_$i", command_data(t, command))
end

command_names(command::CorrAEMCommand) = String["t", "h_d", "v_d", "psi_d"]
command_types(command::CorrAEMCommand) = [Int64, Float64, Float64, Float64] 
command_units(command::CorrAEMCommand) = String["index", "ft/s", "ft/s^2", "deg/s"]

function command_data(t::Int64, command::CorrAEMCommand)
    round_floats(Any[t, command.h_d, command.v_d, command.psi_d], ROUND_NDECIMALS, 
        enable=ENABLE_ROUNDING)
end

function log_adm!(log::TaggedDFLogger, args)
    #[aircraft_number, time_index, dynamics model]
    i, t, adm = args
    push!(log, "Dynamics_$i", dynamics_data(t, adm))
end

dynamics_names(adm::SimpleADM) = String["t", "x", "y", "h", "v", "psi"]
dynamics_types(adm::SimpleADM) = [Int, Float64, Float64, Float64, Float64, Float64]
dynamics_units(adm::SimpleADM) = String["s", "ft", "ft", "ft", "ft/s", "deg"]

function dynamics_data(t::Int64, adm::SimpleADM)
    s = adm.state
    round_floats(Any[t, s.x, s.y, s.h, s.v, s.psi], ROUND_NDECIMALS, enable=ENABLE_ROUNDING)
end

dynamics_names(adm::LLADM) = String["t", "v", "N", "E", "h", "psi", "theta", "phi", "a"]
dynamics_types(adm::LLADM) = [Int, Float64, Float64, Float64, Float64, Float64, Float64, Float64, 
    Float64] 
dynamics_units(adm::LLADM) = String["s", "ft/s", "ft", "ft", "ft", "rad", "rad", "rad", "ft/s^2"]

function dynamics_data(t::Int64, adm::LLADM)
    s = adm.state
    round_floats(Any[t, s.v, s.N, s.E, s.h, s.psi, s.theta, s.phi, s.a], ROUND_NDECIMALS, 
        enable=ENABLE_ROUNDING)
end

function log_wm!(log::TaggedDFLogger, args)
    #[time_index, world model]
    t, wm = args
    for i = 1:wm.number_of_aircraft
        push!(log, "WorldModel_$i", worldmodel_data(t, wm, i)) #[t, x,y,z,vx,vy,vz]
    end
end

worldmodel_names(wm::AirSpace) = String["t", "x", "y", "z", "vx", "vy", "vz"]
worldmodel_types(wm::AirSpace) = [Int, Float64, Float64, Float64, Float64, Float64, Float64] 
worldmodel_units(wm::AirSpace) = String["s", "ft", "ft", "ft", "ft/s", "ft/s", "ft/s"]

function worldmodel_data(t::Int64, wm::AirSpace, aircraft_number::Int)
    s = wm.states[aircraft_number]
    round_floats(Any[t, s.x, s.y, s.h, s.vx, s.vy, s.vh], ROUND_NDECIMALS, enable=ENABLE_ROUNDING)
end

function log_sensor!(log::TaggedDFLogger, args)
    #[aircraft_number, time_index, cas]
    i, t, sr = args
    push!(log, "Sensor_$i", sensor_data(t, sr))
end

sensor_names(sr::Void) = String["t"]
sensor_types(sr::Void) = Type[Int64]
sensor_units(sr::Void) = String["index"]
sensor_data(t::Int64, sr::Void) = Any[] #input=[empty]

function sensor_names(sr::SimpleTCASSensor)
    v = String["t", "r", "r_d", "a", "a_d", "num_intruders"]
    for i = 1:length(sr.output.h)
        push!(v,"h_$i", "h_d_$i")
    end
    v
end
function sensor_types(sr::SimpleTCASSensor)
    v = [Int, Float64, Float64, Float64, Float64, Int] 
    for i = 1:length(sr.output.h)
        push!(v, Float64, Float64)
    end
    v
end
function sensor_units(sr::SimpleTCASSensor)
    v = String["index", "ft", "ft/s", "ft", "ft/s", "num"]
    for i = 1:length(sr.output.h)
        push!(v, "ft", "ft/s")
    end
    v
end
function sensor_data(t::Int64, sr::SimpleTCASSensor)
    #input=[r,r_d, a, a_d],[num_intruders],[h,h_d for each intruder]
    out = sr.output
    num_intruders = length(out.h)
    hhd = Float64[]

    for (h, h_d) in zip(out.h, out.h_d)
        push!(hhd, h, h_d)
    end
    round_floats(vcat(Any[t, out.r, out.r_d, out.a, out.a_d],
                           num_intruders,
                           hhd), ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function sensor_names(sr::ACASXSensor)
    v = String["t", "dz", "z", "psi", "h", "modes", "num_intruders"]
    for i = 1:length(sr.output.intruders)
        v = vcat(v, String["valid_$i", "id_$i", "modes_$i", "sr_$i", "chi_$i", "z_$i", 
            "cvc_$i", "vrc_$i", "vsb_$i"])
    end
    v
end
function sensor_types(sr::ACASXSensor)
    v = [Int64, Float64, Float64, Float64, Float64, Int64, Int64] 
    for i = 1:length(sr.output.intruders)
        v = vcat(v, [Bool, Int64, Int64, Float64, Float64, Float64, Int64, Int64, Int64])
    end
    v
end
function sensor_units(sr::ACASXSensor)
    v = String["index", "ft/s", "ft", "rad", "ft", "n/a", "num"]
    for i = 1:length(sr.output.intruders)
        push!(v, "bool", "num", "n/a", "ft", "rad", "ft", "n/a", "n/a", "n/a")
    end
    v
end

function sensor_data(t::Int64, sr::ACASXSensor)
    #input=[dz,z,psi,h,modes],[num_intruders],[valid,id,modes, 
        #sr,chi,z,cvc,vrc,vsb for each intruder]
    out = sr.output
    own = out.ownInput
    num_intruders = length(out.intruders)
    intr_vec = Any[]
    for intr in out.intruders
        push!(intr_vec, intr.valid, intr.id, intr.modes, intr.sr, intr.chi, intr.z, 
            intr.cvc, intr.vrc, intr.vsb)
    end
    round_floats(vcat(Any[t, own.dz, own.z, own.psi, own.h, own.modes], num_intruders, 
        intr_vec), ROUND_NDECIMALS, enable=ENABLE_ROUNDING)
end

function log_cas!(log::TaggedDFLogger, args)
    #[aircraft_number, time_index, cas]
    i, t, cas = args
    #state=[alarm,target_rate,dh_min,dh_max]
    push!(log, "CAS_$i", cas_data(t, cas))
end

function cas_names(cas::Union{ACASX_CCAS,ACASX_ADD})
    vcat(["t", "ra_active"], ["ownInput.dz", "ownInput.z", "ownInput.psi", "ownInput.h", 
        "ownInput.modes"],
         [["intruderInput[$i].valid", "intruderInput[$i].id", "intruderInput[$i].modes",
         "intruderInput[$i].sr", "intruderInput[$i].chi", "intruderInput[$i].z", 
         "intruderInput[$i].cvc", "intruderInput[$i].vrc", "intruderInput[$i].vsb", 
         "intruderInput[$i].equipage", "intruderInput[$i].quant", 
         "intruderInput[$i].sensitivity_index", "intruderInput[$i].protection_mode"] 
         for i = 1:cas.max_intruders]...,
         ["ownOutput.cc", "ownOutput.vc", "ownOutput.ua", "ownOutput.da", "ownOutput.target_rate",
          "ownOutput.turn_off_aurals", "ownOutput.crossing", "ownOutput.alarm", "ownOutput.alert",
          "ownOutput.dh_min", "ownOutput.dh_max", "ownOutput.sensitivity_index", "ownOutput.ddh"],
         [["intruderOutput[$i].id", "intruderOutput[$i].cvc", "intruderOutput[$i].vrc",
          "intruderOutput[$i].vsb", "intruderOutput[$i].tds", "intruderOutput[$i].code"]
          for i = 1:cas.max_intruders]...)
end
function cas_types(cas::Union{ACASX_CCAS,ACASX_ADD})
    vcat([Int64, Bool], [Float64, Float64, Float64, Float64, Int64], 
         [[Bool, Int64, Int64, Float64, Float64, Float64, Int64, Int64, Int64, 
         Int64, Int64,  Int64, Int64] for i = 1:cas.max_intruders]...,
         [Int64, Int64, Int64, Int64, Float64, Bool, Bool, Bool, Bool, 
         Float64, Float64, Int64, Float64], [[Int64, Int64, Int64,
          Int64, Float64, Int64] for i = 1:cas.max_intruders]...)
end
function cas_units(cas::Union{ACASX_CCAS,ACASX_ADD})
    vcat(["index", "bool"], ["ft/s", "ft", "rad", "ft/s", "num"],
        [["bool", "num", "num", "ft", "rad", "ft", "n/a", "n/a", "n/a", "enum",
           "ft", "num", "num"] for i = 1:cas.max_intruders]...,
         ["n/a", "n/a", "n/a", "n/a", "ft/s", "bool", "bool", "bool", "boobool",
          "ft/s", "ft/s", "num", "ft/s^2"],
         [["num", "n/a", "n/a", "n/a", "n/a", "n/a"]
          for i = 1:cas.max_intruders]...)
end
function cas_data(t::Int64, cas::Union{ACASX_CCAS,ACASX_ADD}) #log everything
    ra_active = (cas.output.dh_min > -9999.0 || cas.output.dh_max < 9999.0)::Bool
    ownInput = Any[cas.input.ownInput.dz,
             cas.input.ownInput.z,
             cas.input.ownInput.psi,
             cas.input.ownInput.h,
             cas.input.ownInput.modes]

    intruderInputs = vcat([Any[cas.input.intruders[i].valid,
                             cas.input.intruders[i].id,
                             cas.input.intruders[i].modes,
                             cas.input.intruders[i].sr,
                             cas.input.intruders[i].chi,
                             cas.input.intruders[i].z,
                             cas.input.intruders[i].cvc,
                             cas.input.intruders[i].vrc,
                             cas.input.intruders[i].vsb,
                             cas.input.intruders[i].equipage.val,
                             cas.input.intruders[i].quant,
                             cas.input.intruders[i].sensitivity_index,
                             cas.input.intruders[i].protection_mode]
                          for i=1:length(cas.input.intruders)]...)

    ownOutput = Any[cas.output.cc,
                   cas.output.vc,
                   cas.output.ua,
                   cas.output.da,
                   cas.output.target_rate,
                   cas.output.turn_off_aurals,
                   cas.output.crossing,
                   cas.output.alarm,
                   cas.output.alert,
                   cas.output.dh_min,
                   cas.output.dh_max,
                   cas.output.sensitivity_index,
                   cas.output.ddh]

    intruderOutputs = vcat([Any[cas.output.intruders[i].id,
                              cas.output.intruders[i].cvc,
                              cas.output.intruders[i].vrc,
                              cas.output.intruders[i].vsb,
                              cas.output.intruders[i].tds,
                              cas.output.intruders[i].code]
                          for i=1:length(cas.output.intruders)]...)

    round_floats(vcat(t, ra_active,
                           ownInput,
                           intruderInputs,
                           ownOutput,
                           intruderOutputs), ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_response!(log::TaggedDFLogger, args)
    #[aircraft_number, time_index, cas]
    i, t, pr = args
    push!(log, "Response_$i", response_data(t, pr))
end

response_names(pr::StochasticLinearPR) = String["t", "state", "displayRA", "response", 
    "v_d", "h_d", "psi_d", "logProb"]
response_types(pr::StochasticLinearPR) = [Int64, String, String, String, Float64, Float64, 
    Float64, Float64] 
response_units(pr::StochasticLinearPR) = String["enum", "enum", "enum", "ft/s^2", "ft/s", 
    "deg/s", "float"]

function response_data(t::Int64, pr::StochasticLinearPR)
    round_floats(Any[t, pr.state,
                          pr.displayRA,
                          pr.response,
                          pr.output.t,
                          pr.output.v_d,
                          pr.output.h_d,
                          pr.output.psi_d,
                          pr.output.logProb], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

response_names(pr::LLDetPR) = String["t", "state", "timer", "t_s", "v_d", "h_d", "psi_d", "logProb"]
response_types(pr::LLDetPR) = [Int64, Symbol, Int64, Float64, Float64, Float64, Float64, Float64]   
response_units(pr::LLDetPR) = String["int", "enum", "s", "s", "ft/s^2", "ft/s", "deg/s", "float"]

function response_data(t::Int64, pr::LLDetPR)
    round_floats(Any[t, pr.state,
                          pr.timer,
                          pr.output.t,
                          pr.output.v_d,
                          pr.output.h_d,
                          pr.output.psi_d,
                          pr.output.logProb], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_run_info!(log::TaggedDFLogger, args)
  # called only once when isEndState is true
  reward, md_time, hmd, vmd, nmac = args
  push!(log, "run_info", Any[reward, md_time, hmd, vmd, nmac])
end

run_info_names() = String["reward", "md_time", "hmd", "vmd", "nmac"]
run_info_types() = [Float64, Float64, Float64, Float64, Bool]
run_info_units() = String["float", "s", "ft", "ft", "bool"]

function log_logProb!(log::TaggedDFLogger, args)
    #[time_index, logProb]
    t, logProb = args
    push!(log, "logProb", round_floats(Any[t, logProb], ROUND_NDECIMALS, 
        enable=ENABLE_ROUNDING))
end

logprob_names() = String["t", "logprob"]
logprob_types() = [Int64, Float64]
logprob_units() = String["int", "n/a"]

function round_floats(v::Vector{Any}, ndigits::Int64; enable::Bool=true)
  out = v
  if enable
    out = map(v) do x
      return isa(x, AbstractFloat) ? round(x, ndigits) : x
    end
  end
  return out
end

#mods x to the range [-b, b]
function to_plusminus_b(x::AbstractFloat, b::AbstractFloat)
  z = mod(x, 2 * b)
  return (z > b) ? (z - 2 * b) : z
end

to_plusminus_180(x::AbstractFloat) = to_plusminus_b(x, 180.0)

end #module
