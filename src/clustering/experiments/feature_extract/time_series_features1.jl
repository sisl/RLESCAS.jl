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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl"))

using RLESUtils.MathUtils
using RLESUtils.LookupCallbacks
using RLESUtils.FileUtils
using RLESUtils.StringUtils
using CSVFeatures
using DataFrameFeatures

const IN_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs/csv")
const OUT_DIR = Pkg.dir("RLESCAS/src/clustering/data/dasc_nmacs_ts_feats") #time series feats (as opposed to static feats)

const FEATURE_MAP = LookupCallback[
  LookupCallback("ra_detailed.ra_active", bool),
  LookupCallback("ra_detailed.ownInput.dz"),
  LookupCallback(["ra_detailed.ownInput.z", "ra_detailed.intruderInput[1].z"], (z1, z2) -> z2 - z1),
  LookupCallback("ra_detailed.ownInput.psi"),
  LookupCallback("ra_detailed.intruderInput[1].sr"),
  LookupCallback("ra_detailed.intruderInput[1].chi"),
  LookupCallback("ra_detailed.intruderInput[1].vrc", x -> x == 0), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderInput[1].vrc", x -> x == 1), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderInput[1].vrc", x -> x == 2), #split categorical to 1-hot
  LookupCallback("ra_detailed.ownOutput.cc", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.cc", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.cc", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.vc", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.vc", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.vc", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.ua", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.ua", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.ua", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.da", x -> bin(int(x), 3)[1] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.da", x -> bin(int(x), 3)[2] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.da", x -> bin(int(x), 3)[3] == '1'), #categorical 3-bit
  LookupCallback("ra_detailed.ownOutput.target_rate"),
  LookupCallback("ra_detailed.ownOutput.crossing", bool),
  LookupCallback("ra_detailed.ownOutput.alarm", bool),
  LookupCallback("ra_detailed.ownOutput.alert", bool),
  LookupCallback("ra_detailed.intruderOutput[1].vrc", x -> x == 0), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderOutput[1].vrc", x -> x == 1), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderOutput[1].vrc", x -> x == 2), #split categorical to 1-hot
  LookupCallback("ra_detailed.intruderOutput[1].tds"),
  LookupCallback("response.state", x -> x == "none"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "stay"), #split categorical to 1-hot
  LookupCallback("response.state", x -> x == "follow"), #split categorical to 1-hot
  LookupCallback("response.timer"),
  LookupCallback("response.h_d"),
  LookupCallback("response.psi_d"),
  LookupCallback("adm.v"),
  LookupCallback("adm.h")
  ]

const FEATURE_NAMES = ASCIIString[
  "RA",
  "vert_rate",
  "alt_diff",
  "psi",
  "intr_sr",
  "intr_chi",
  "intr_vrc0",
  "intr_vrc1",
  "intr_vrc2",
  "cc1",
  "cc2",
  "cc3",
  "vc1",
  "vc2",
  "vc3",
  "ua1",
  "ua2",
  "ua3",
  "da1",
  "da2",
  "da3",
  "target_rate",
  "crossing",
  "alarm",
  "alert",
  "intr_out_vrc0",
  "intr_out_vrc1",
  "intr_out_vrc2",
  "intr_out_tds",
  "response_none",
  "response_stay",
  "response_follow",
  "response_timer",
  "response_h_d",
  "response_psi_d",
  "v",
  "h"
  ]

function is_converging(psi1::Float64, chi1::Float64, psi2::Float64, chi2::Float64)
  #println("psi1=$psi1, chi1=$chi1, psi2=$psi2, chi2=$chi2")
  if abs(chi1) > pi/2 && abs(chi2) > pi/2 #flying away from each other
    return false
  end
  z1 = to_plusminus_pi(psi2 - psi1)
  z2 = to_plusminus_pi(psi1 - psi2)
  return z1 * chi1 <= 0 && z2 * chi2 <= 0
end

const ADD_FEATURE_MAP = LookupCallback[
  LookupCallback(["psi_1", "intr_chi_1", "psi_2", "intr_chi_2"], is_converging)
  ]

const ADD_FEATURE_NAMES = ASCIIString[
  "converging"
  ]

function csvs2dataframes()
  csvfiles = readdir_ext("csv", IN_DIR)
  df_files = csv_to_dataframe(csvfiles, FEATURE_MAP, FEATURE_NAMES, outdir=OUT_DIR)
  add_features!(df_files, ADD_FEATURE_MAP, ADD_FEATURE_NAMES, overwrite=true)
end

csvs2dataframes()
