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
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar.jl"))

using Base.Test

@test get_real(5, 1.2345) == 123450
@test_approx_eq_eps get_real(-4, 1234.0) 0.1234 1e-10

r1 = Float64[1, 2, 3, 4, 5]
r2 = Float64[1, 0, 5, 2, 5]
#diff=[0,2,-2,2,0]
@test diff_eq(r1, r2, 2.0) == [false, true, false, true, false]
@test diff_lte(r1, r2, 1.0) == [true, false, true, false, true]
@test diff_lt(r1, r2, 0.0) == [false, false, true, false, false]

v1 = Bool[false, true, true, false, false]
v2 = Bool[false, false, true, true, true]
@test eventually(v1) = [true, true, true, false, false]
@test globally(v2) == [false, false, true, true, true]
@test until(v1, v2) == [false, true, true, true, true]
@test until(v2, v1) == [false, true, true, false, false]
@test weak_until(v1, v2) == [false, true, true, true, true]
@test weak_until(v2, v1) == [false, true, true, true, true]
@test release(v1, v2) == [false, true, true, true, true]
@test release(v2, v1) == [false, true, true, false, false]
@test next_(v1) == [true, true, false, false, false]
@test next_(v2) == [false, true, true, true, false]
@test implies(v1, v2) == [true, false, true, true, true]
@test implies(v2, v1) == [true, true, true, false, false]
@test count_eq(v1, 2.0) == [true, true, false, false, false]
@test count_lt(v1, 2.0) == [false, false, true, true, true]
@test count_lte(v1, 1.0) == [false, false, true, true, true]
@test count_gt(v1, 1.0) == [true, true, false, false, false]
@test count_gte(v1, 1.0) == [true, true, true, false, false]

r1 = Float64[1, 2, -1, 0, 1, 0]
r2 = Float64[2, 0, 1, 0, -2, -5]
@test sign_(r1, r2) == [true, true, false, true, false, true]
