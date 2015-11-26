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

using SISLES
using SISLES.GenerativeModel

function defineSimParams(;
                         nmac_r::Float64 = 500.0,
                         nmac_h::Float64 = 100.0,
                         max_steps::Int64 = 50,
                         num_aircraft::Int64 = 3,
                         encounter_seed::Uint64 = UInt64(0),
                         encounterModel::Symbol = :StarDBN, #{:PairwiseCorrAEMDBN, :StarDBN}
                         pilotResponseModel::Symbol = :ICAO_all, #:SimplePR, :StochasticLinear, :FiveVsNone, :ICAO_all
                         end_on_nmac::Bool = true,
                         encounter_file::AbstractString = Pkg.dir("SISLES/src/Encounter/CorrAEMImpl/params/cor.txt"),
                         quant::Int64 = 25,
                         libcas::AbstractString = Pkg.dir("CCAS/libcas0.8.6/lib/libcas"),
                         libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.8.6/parameters/0.8.5.standard.r13.xa.config.txt")
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.9.0/lib/libcas"),
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.9.0/parameters/0.9.0.r14.rev2_3_4candidate07_active.config.txt")
                         #libcas::AbstractString = Pkg.dir("CCAS/libcas0.9.2/lib/libcas"),
                         #libcas_config::AbstractString = Pkg.dir("CCAS/libcas0.9.2/parameters/0.9.2.r14.rev3_7candidate08_active.config.txt")
                         )
  p = ACASX_Multi_params()

  p.nmac_r = nmac_r
  p.nmac_h = nmac_h
  p.max_steps = max_steps
  p.num_aircraft = num_aircraft
  p.encounter_seed = encounter_seed
  p.encounterModel = encounterModel
  p.pilotResponseModel = pilotResponseModel
  p.end_on_nmac = end_on_nmac
  p.encounter_file = encounter_file
  p.quant = quant
  p.libcas = libcas
  p.libcas_config = libcas_config

  return p
end

defineSim(p::ACASX_Multi_params) = ACASX_Multi(p)
