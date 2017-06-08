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

module Config_ACASX_GM

export defineSimParams, defineSim

using SISLES
using SISLES.GenerativeModel
using AdaptiveStressTesting

function defineSimParams(;encounter_number::Int64 = 1,
                         encounter_seed::UInt64 = UInt64(0),
                         nmac_r::Float64 = 500.0,
                         nmac_h::Float64 = 100.0,
                         max_steps::Int64 = 51,
                         num_aircraft::Int64 = 2,
                         encounter_model::Symbol = :LLCEMDBN, #:LLCEMDBN, :StarDBN
                         encounter_equipage::Symbol = :EvE, #:EvE, :EvU
                         response_model::Symbol = :ICAO, #:ICAO
                         cas_model::Symbol = :CCAS, #:CCAS, :ADD
                         dynamics_model::Symbol = :LLADM, #:LLADM
                         end_on_nmac::Bool = true,
                         encounter_file::AbstractString = Pkg.dir("SISLES/src/Encounter/CorrAEMImpl/params/cor.txt"),
                         command_method::Symbol = :DBN,
                         initial_sample_file::AbstractString = Pkg.dir("RLESCAS/encounters/initial.txt"),
                         transition_sample_file::AbstractString = Pkg.dir("RLESCAS/encounters/transition.txt"),
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.8.6/lib/libcas"), #empty if using :ADD
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.8.6/parameters/0.8.5.standard.r13.xa.config.txt")
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.9.0/lib/libcas"),
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.9.0/parameters/0.9.0.r14.rev2_3_4candidate07_active.config.txt")
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.9.2/lib/libcas"),
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.9.2/parameters/0.9.2.r14.rev3_7candidate08_active.config.txt")
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.9.3/lib/libcas"),
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.9.3/parameters/0.9.3.standard.r14.xa.config.txt")
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.10.0/lib/libcas"),
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.10.0/parameters/0.10.0.standard.r15_pre25iter93.xa.tcas.config.txt")
                         libcas::AbstractString = Pkg.dir("CCAS/libcas0.10.1/lib/libcas"),
                         libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.10.1/parameters/0.10.1.standard.r15mtf.tcas.xa.config.txt"),
                         libcas2::Union{Void,String}=nothing,
                         libcas2_config::Union{Void,String}=nothing
                         )
  p = ACASX_GM_params()

  p.encounter_number = encounter_number
  p.encounter_seed = encounter_seed
  p.nmac_r = nmac_r
  p.nmac_h = nmac_h
  p.max_steps = max_steps
  p.num_aircraft = num_aircraft
  p.response_model = response_model
  p.cas_model = cas_model
  p.encounter_equipage = encounter_equipage
  p.dynamics_model = dynamics_model
  p.end_on_nmac = end_on_nmac
  p.command_method = command_method
  p.encounter_file = encounter_file
  p.initial_sample_file = initial_sample_file
  p.transition_sample_file = transition_sample_file
  p.libcas = libcas
  p.libcas_config = libcas_config

  if libcas2 == nothing || libcas2_config == nothing 
      return p #single sim run
  end

  p2 = deepcopy(p)
  p2.libcas = libcas2
  p2.libcas_config = libcas2_config

  return (p, p2) #dual sim run
end

#single sim run
defineSim(p::ACASX_GM_params) = ACASX_GM(p)

#dual sim run
defineSim(p::Tuple{ACASX_GM_params,ACASX_GM_params}) = DualSim(ACASX_GM(p[1]), ACASX_GM(p[2]))

end #module
