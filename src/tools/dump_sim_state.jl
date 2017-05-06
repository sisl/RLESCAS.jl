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

using DataFrames
using SISLES
using RLESUtils, MathUtils

const COLTYPES = 
        [
            Bool,
            Float64,
            Float64,
            Float64,
            Float64,
            Float64,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Float64,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Float64,
            Bool ,
            Bool,
            Bool,
            Float64,
            Float64,
            Float64,
            Float64,
            Float64,
            Bool,
            Float64,
            Float64,
            Float64,
            Float64,
            Float64,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Float64,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Bool,
            Float64,
            Bool,
            Bool,
            Bool,
            Float64,
            Float64,
            Float64,
            Float64,
            Float64,
            Bool,
            Float64,
            Float64
        ]

const COLNAMES = 
        [
            :RA_1,
            :vert_rate_1,
            :alt_diff_1,
            :psi_1,
            :intr_sr_1,
            :intr_chi_1,
            :intr_vrc0_1,
            :intr_vrc1_1,
            :intr_vrc2_1,
            :cc0_1,
            :cc1_1,
            :cc2_1,
            :vc0_1,
            :vc1_1,
            :vc2_1,
            :ua0_1,
            :ua1_1,
            :ua2_1,
            :da0_1,
            :da1_1,
            :da2_1,
            :target_rate_1,
            :crossing_1,
            :alarm_1,
            :alert_1,
            :intr_out_vrc0_1,
            :intr_out_vrc1_1,
            :intr_out_vrc2_1,
            :intr_out_tds_1,
            :response_none_1,
            :response_stay_1,
            :response_follow_1,
            :response_timer_1,
            :response_h_d_1,
            :response_psi_d_1,
            :v_1,
            :h_1,
            :RA_2,
            :vert_rate_2,
            :alt_diff_2,
            :psi_2,
            :intr_sr_2,
            :intr_chi_2,
            :intr_vrc0_2,
            :intr_vrc1_2,
            :intr_vrc2_2,
            :cc0_2,
            :cc1_2,
            :cc2_2,
            :vc0_2,
            :vc1_2,
            :vc2_2,
            :ua0_2,
            :ua1_2,
            :ua2_2,
            :da0_2,
            :da1_2,
            :da2_2,
            :target_rate_2,
            :crossing_2,
            :alarm_2,
            :alert_2,
            :intr_out_vrc0_2,
            :intr_out_vrc1_2,
            :intr_out_vrc2_2,
            :intr_out_tds_2,
            :response_none_2,
            :response_stay_2,
            :response_follow_2,
            :response_timer_2,
            :response_h_d_2,
            :response_psi_d_2,
            :v_2,
            :h_2,
            :converging,
            :abs_alt_diff,
            :horizontal_range
        ]

extract_state(sim::ACASX_GM) = extract_state(Vector, sim::ACASX_GM)

function extract_state(::Type{DataFrame}, sim::ACASX_GM)
    D = DataFrame(COLTYPES, COLNAMES, 0)
    push!(D, extract_state(Vector, sim))
    D
end

function extract_state(::Type{Vector}, sim::ACASX_GM)
    ra_active_1 = (sim.cas[1].output.dh_min > -9999.0 || sim.cas[1].output.dh_max < 9999.0)::Bool
    ra_active_2 = (sim.cas[2].output.dh_min > -9999.0 || sim.cas[2].output.dh_max < 9999.0)::Bool
    converging = is_converging(sim.cas[1].input.ownInput.psi,
        sim.cas[1].input.intruders[1].chi,
        sim.cas[2].input.ownInput.psi,
        sim.cas[2].input.intruders[1].chi)
    abs_alt_diff = abs(sim.dm[2].state.h - sim.dm[1].state.h)
    horizontal_range = sqrt(max(0.0, sim.cas[1].input.intruders[1].sr^2 - abs_alt_diff^2))
    v = [
           ra_active_1,
           sim.cas[1].input.ownInput.dz,
           sim.cas[1].input.ownInput.z,
           sim.cas[1].input.ownInput.psi,
           sim.cas[1].input.intruders[1].sr,
           sim.cas[1].input.intruders[1].chi,
           sim.cas[1].input.intruders[1].vrc == 0,
           sim.cas[1].input.intruders[1].vrc == 1,
           sim.cas[1].input.intruders[1].vrc == 2,
           bin(sim.cas[1].output.cc, 3)[1] == '1',
           bin(sim.cas[1].output.cc, 3)[2] == '1',
           bin(sim.cas[1].output.cc, 3)[3] == '1',
           bin(sim.cas[1].output.vc, 3)[1] == '1',
           bin(sim.cas[1].output.vc, 3)[2] == '1',
           bin(sim.cas[1].output.vc, 3)[3] == '1',
           bin(sim.cas[1].output.ua, 3)[1] == '1',
           bin(sim.cas[1].output.ua, 3)[2] == '1',
           bin(sim.cas[1].output.ua, 3)[3] == '1',
           bin(sim.cas[1].output.da, 3)[1] == '1',
           bin(sim.cas[1].output.da, 3)[2] == '1',
           bin(sim.cas[1].output.da, 3)[3] == '1',
           sim.cas[1].output.target_rate,
           sim.cas[1].output.crossing,
           sim.cas[1].output.alarm,
           sim.cas[1].output.alert,
           sim.cas[1].output.intruders[1].vrc == 0,
           sim.cas[1].output.intruders[1].vrc == 1,
           sim.cas[1].output.intruders[1].vrc == 2,
           sim.cas[1].output.intruders[1].tds,
           sim.pr[1].state == "none",
           sim.pr[1].state == "stay",
           sim.pr[1].state == "follow",
           sim.pr[1].timer,
           sim.pr[1].output.h_d,
           sim.pr[1].output.psi_d,
           sim.dm[1].state.v,
           sim.dm[1].state.h,
           ra_active_2,
           sim.cas[2].input.ownInput.dz,
           sim.cas[2].input.ownInput.z,
           sim.cas[2].input.ownInput.psi,
           sim.cas[2].input.intruders[1].sr,
           sim.cas[2].input.intruders[1].chi,
           sim.cas[2].input.intruders[1].vrc == 0,
           sim.cas[2].input.intruders[1].vrc == 1,
           sim.cas[2].input.intruders[1].vrc == 2,
           bin(sim.cas[2].output.cc, 3)[1] == '1',
           bin(sim.cas[2].output.cc, 3)[2] == '1',
           bin(sim.cas[2].output.cc, 3)[3] == '1',
           bin(sim.cas[2].output.vc, 3)[1] == '1',
           bin(sim.cas[2].output.vc, 3)[2] == '1',
           bin(sim.cas[2].output.vc, 3)[3] == '1',
           bin(sim.cas[2].output.ua, 3)[1] == '1',
           bin(sim.cas[2].output.ua, 3)[2] == '1',
           bin(sim.cas[2].output.ua, 3)[3] == '1',
           bin(sim.cas[2].output.da, 3)[1] == '1',
           bin(sim.cas[2].output.da, 3)[2] == '1',
           bin(sim.cas[2].output.da, 3)[3] == '1',
           sim.cas[2].output.target_rate,
           sim.cas[2].output.crossing,
           sim.cas[2].output.alarm,
           sim.cas[2].output.alert,
           sim.cas[2].output.intruders[1].vrc == 0,
           sim.cas[2].output.intruders[1].vrc == 1,
           sim.cas[2].output.intruders[1].vrc == 2,
           sim.cas[2].output.intruders[1].tds,
           sim.pr[2].state == "none",
           sim.pr[2].state == "stay",
           sim.pr[2].state == "follow",
           sim.pr[2].timer,
           sim.pr[2].output.h_d,
           sim.pr[2].output.psi_d,
           sim.dm[2].state.v,
           sim.dm[2].state.h,
           converging,
           abs_alt_diff, 
           horizontal_range 
        ]
    v
end

function is_converging(psi1::Float64, chi1::Float64, psi2::Float64, chi2::Float64)
    #println("psi1=$psi1, chi1=$chi1, psi2=$psi2, chi2=$chi2")
    if abs(chi1) > pi/2 && abs(chi2) > pi/2 #flying away from each other
        return false
    end
    z1 = to_plusminus_pi(psi2 - psi1)
    z2 = to_plusminus_pi(psi1 - psi2)
    isconverge = z1 * chi1 <= 0 && z2 * chi2 <= 0
    isconverge
end

function print_state(filename::AbstractString, sim::ACASX_GM)
    if !endswith(filename, ".csv")
        filename *= ".csv"
    end
    state = extract_state(DataFrame, sim)
    writetable(filename, state) 
end
