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

module Visualize

export trajPlot
export pgfplot_hor, pgfplot_alt, pgfplot_heading, pgfplot_vrate

import Compat.ASCIIString

using ..DefineSave
using ..SaveHelpers
using ..AddSupplementary

include("../helpers/TikzUtils.jl")
include("vis_captions.jl")
using .TikzUtils
using .VisCaptions

using Iterators
using TikzPictures
import PGFPlots
import PGFPlots: Plots, Axis, GroupPlot

using RLESUtils, MathUtils, PGFPlotUtils

const RA_STYLE_MAP = [
    ((ra, h_d) -> ra && abs(h_d) < 5, "mark options={color=gray}, mark=*"),
    ((ra, h_d) -> ra && 5 <= h_d < 30, "mark options={color=orange}, mark=*"),
    ((ra, h_d) -> ra && 30 <= h_d, "mark options={color=red}, mark=*"),
    ((ra, h_d) -> ra && -30 < h_d <= -5, "mark options={color=cyan}, mark=*"),
    ((ra, h_d) -> ra && h_d <= -30, "mark options={color=violet}, mark=*")
    ]

const RESPONSE_STYLE_MAP = [
    (r -> r == "stay", "mark options={color=black}, mark=-"),
    (r -> r == "follow", "mark options={color=black}, mark=asterisk")
    ]

#xy
function pgfplot_hor(d::TrajLog)
    plotArray = vcat(pplot_line(d, "WorldModel", :y, :x),
        pplot_startpoint(d, "WorldModel", :y, :x, "top"), # label start point
        pplot_aircraft_num(d, "WorldModel", :y, :x, startdist = 3.4)) # label aircraft numbers
    xmin, xmax, ymin, ymax = manual_axis_equal(d, "WorldModel", :y, :x)
    ax = Axis(plotArray,
        ylabel = "N ($(get_unit(d, "WorldModel", 1, :x)))",
        xlabel = "E ($(get_unit(d, "WorldModel", 1, :y)))",
        title = "Horizontal Position",
        style = "xmin=$xmin,xmax=$xmax,ymin=$ymin,ymax=$ymax,enlarge x limits=true," *
            "enlarge y limits=true,axis equal,clip mode=individual")
    ax
end

#altitude vs. time
function pgfplot_alt(d::TrajLog)
    plotArray = vcat(pplot_z_label270s(d), # label270 short
        pplot_line(d, "WorldModel", :t, :z),
        pplot_startpoint(d, "WorldModel", :t, :z, "side", overrideangle = 0), # label start point
        pplot_aircraft_num(d, "WorldModel", :t, :z, startdist = 3.4)) # label aircraft numbers

    ax = Axis(plotArray,
            xlabel = "time ($(get_unit(d, "WorldModel", 1, :t)))",
            ylabel = "h ($(get_unit(d, "WorldModel", 1, :z)))",
            title = "Altitude vs. Time",
            style = "clip=false,clip mode=individual")
    ax
end

#heading vs time
function pgfplot_heading(d::TrajLog)
    plotArray = vcat(pplot_aircraft_num(d, "Dynamics", :t, :psi, fy=psidot_from_psi), # label aircraft numbers
        pplot_line(d, "Dynamics", :t, :psi, fy=psidot_from_psi))
    ax = Axis(plotArray,
        xlabel = "time ($(get_unit(d, "Dynamics", 1, :t)))",
        ylabel = "psidot ($(get_unit(d, "Dynamics", 1, :psi))/s)",
        title = "Heading Rate vs. Time")
    ax
end

#vertical rate vs time
function pgfplot_vrate(d::TrajLog)
    plotArray = vcat(pplot_aircraft_num(d, "WorldModel", :t, :vz), # label aircraft numbers
        pplot_line(d, "WorldModel", :t, :vz))
    ax = Axis(plotArray,
        xlabel = "time ($(get_unit(d, "WorldModel", 1, :t)))",
        ylabel = "vh ($(get_unit(d, "WorldModel", 1, :vz)))",
        title = "Vertical Rate vs. Time")
    ax
end

function pgfplotLog(d::TrajLog)
    tps = TikzPicture[]

    #xy and tz group
    g = GroupPlot(2, 2, groupStyle = "horizontal sep = 2.2cm, vertical sep = 2.2cm")

    #xy
    push!(g, pgfplot_hor(d))

    #altitude vs time
    push!(g, pgfplot_alt(d))

    #heading rate vs time
    push!(g, pgfplot_heading(d))

    #vertical rate vs time
    push!(g, pgfplot_vrate(d))

    tp = PGFPlots.plot(g)
    use_geometry_package!(tp, landscape = true)
    use_aircraftshapes_package!(tp)

    push!(tps, tp)
    
    tps
end

function manual_axis_equal(d::TrajLog, field::AbstractString, xname::Symbol, 
    yname::Symbol; fx::Function = identity, fy::Function = identity)

    xmin = ymin = realmax(Float64)
    xmax = ymax = -realmax(Float64)

    for i = 1:get_num_aircraft(d)
        df = get_log(d, field, i) 

        #plot trajectories
        xvals = convert(Array, df[xname]) 
        yvals = convert(Array, df[yname]) 
        
        xvals = fx(xvals)
        yvals = fy(yvals)

        tempmin, tempmax = extrema(xvals)
        xmin = min(xmin, tempmin)
        xmax = max(xmax, tempmax)
        tempmin, tempmax = extrema(yvals)
        ymin = min(ymin, tempmin)
        ymax = max(ymax, tempmax)
    end

    xrange = xmax - xmin
    yrange = ymax - ymin
    plot_range = max(xrange, yrange)

    delta = abs(yrange - xrange) / 2
    if yrange > xrange
        xmin -= delta
        xmax += delta
    else
        ymin -= delta
        ymax += delta
    end

    (xmin, xmax, ymin, ymax)
end

#xname = field name of x variable
#yname = field name of y variable
function pplot_aircraft_num(d::TrajLog, field::AbstractString, xname::Symbol, 
    yname::Symbol; ind_start::Int64 = 1,
                            displaystart::Bool = true,
                            displayend::Bool = true,
                            startdist::Float64 = 2.0,
                            enddist::Float64 = 2.0,
                            scale::Float64 = 0.55,
                            fx::Function = identity,
                            fy::Function = identity)

    plotArray = Plots.Plot[]

    for i = 1:get_num_aircraft(d)
        df = get_log(d, field, i) 

        #plot trajectories
        xvals = convert(Array, df[xname])
        yvals = convert(Array, df[yname])

        # apply user-supplied transformations
        xvals = fx(xvals)
        yvals = fy(yvals)

        if displaystart
            # determine where to put the label for the first: left or right
            x1 = xvals[ind_start]
            y1 = yvals[ind_start]
            x2 = xvals[ind_start + 1]

            #mark aircraft number
            dir = x2 < x1  ? "right" : "left"
            push!(plotArray, Plots.Node("$i", x1, y1,
                                  style = "$(dir)=$(startdist)mm,scale=$(scale),rotate=0"))
        end

        if displayend
            # determine where to put the label for the last: left or right
            xend = xvals[end]
            yend = yvals[end]
            xend_1 = xvals[end - 1]

            #mark aircraft number
            dir = xend_1 < xend  ? "right" : "left"
            push!(plotArray, Plots.Node("$i", xend, yend,
                                  style = "$(dir)=$(enddist)mm,scale=$(scale),rotate=0"))
        end
    end
    plotArray
end

#xname = field name of x variable
#yname = field name of y variable
#view = "top" or "side" view of aircraft
#angle = angle of aircraft in degrees.  Pointing right is 0.  nothing = auto-determine from first and second points.
#minwidth = minimum width of aircraft icon in cm

function pplot_startpoint(d::TrajLog, field::AbstractString, xname::Symbol, 
    yname::Symbol, view::AbstractString;
                          overrideangle::Union{Void, Real} = nothing,
                          ind_start::Int64 = 1,
                          minwidth::Float64 = 0.65,
                          fx::Function = identity,
                          fy::Function = identity)
    plotArray = Plots.Plot[]
    for i = 1:get_num_aircraft(d)
        df = get_log(d, field, i)

        #plot trajectories
        xvals = convert(Array, df[xname])
        yvals = convert(Array, df[yname])

        # apply user-supplied transformations
        xvals = fx(xvals)
        yvals = fy(yvals)

        x1 = xvals[ind_start]
        y1 = yvals[ind_start]

        # determine angle of aircraft if not given
        if overrideangle == nothing
            x2 = xvals[ind_start + 1]
            y2 = yvals[ind_start + 1]
    
            angle = atan2(y2 - y1, x2 - x1) |> rad2deg
        else
            angle = overrideangle
        end

        #mark aircraft start point
        push!(plotArray, Plots.Node("", x1, y1,
            style = "aircraft $view,draw=white,thin,fill=black,minimum width=$(minwidth)cm,rotate=$angle"))
        #\node [aircraft top,fill=black,minimum width=1cm,rotate=30] at (0,0) {};
        #\node at (axis cs:-14746.707634583, 8514.015622487) [left=2.0mm,scale=0.55,rotate=0] {2};
    end

    plotArray
end

function pplot_z_label270s(d::TrajLog; start_time::Int64 = 0, end_time::Int64 = 51, 
    label_scale::Float64 = 0.45)

    @assert start_time < end_time

    plotArray = Plots.Plot[]
    for i = 1:get_num_aircraft(d)
        wm = d["WorldModel_$i"]
        cas = d["CAS_$i"]
        ts = convert(Array, wm[:t])
        filter!(t -> start_time <= t <= end_time, ts) #filter based on start/end times

        #short labels
        prev_label = ""

        dirs = closest_is_above(d, i) 
        xs = convert(Array, wm[:t])
        ys = convert(Array, wm[:z])
        for t in ts
            label = cas[t, :label270_short]
            if prev_label != label
                label_ = replace(label, "_", "\\_") #convert underscores to latex escape sequence
                label_ = "\\textbf{$(label_)}"
                dir = dirs[t] ? "left" : "right" #left=below, right=above
                push!(plotArray,Plots.Node(label_, xs[t], ys[t], 
                    style="rotate=90,scale=$(label_scale),$dir=2mm,fill=white,rectangle,rounded corners=3pt"))
                prev_label = label

            end
        end
    end
    plotArray
end

function closest_is_above(d::TrajLog, own_id::Int64)
    wm = d["WorldModel_$(own_id)"]
    h1 = convert(Array, wm[:z])
    hs = copy(h1) 
    for i = 1:get_num_aircraft(d)
        if i != own_id
            wm_i = d["WorldModel_$i"]
            h2 = convert(Array, wm_i[:z])
            hs = hcat(hs, h2-h1)
        end
    end
    v, i = findmin(abs(hs), 2)
    minvals = squeeze(hs[i], 2)

    minvals .>= 0.0
end

function pplot_line(d::TrajLog, field::AbstractString,
                         xname::Symbol,
                         yname::Symbol;
                         mark_ra::Bool = true,
                         fx::Function = identity,
                         fy::Function = identity)

    plotArray = Plots.Plot[]
    for i = 1:get_num_aircraft(d)
        df = get_log(d, field, i)

        #plot trajectories
        xvals = convert(Array, df[xname])
        yvals = convert(Array, df[yname])

        # apply user function transforms
        xvals = fx(xvals)
        yvals = fy(yvals)

        # apply time filters
        # TODO:...

        push!(plotArray,Plots.Linear(xvals, yvals, 
            style="mark options={color=blue}", mark="*"))

        # RA markings
        if mark_ra
            #mark times of RA active
            t_style_array = get_ra_style(d, i)

            for (times, style) = t_style_array
                if !isempty(times)
                    push!(plotArray, Plots.Scatter(xvals[times], yvals[times], style = style))
                end
            end

            #mark times where pilot was following RA
            t_style_array = get_response_style(d, i)

            for (times, style) = t_style_array
                if !isempty(times)
                    push!(plotArray,Plots.Scatter(xvals[times], yvals[times], style = style))
                end
            end
        end
    end
    plotArray
end

function psidot_from_psi(psi::Vector{Float64})
    # Numerical differentiation
    psid = [angle_diff_rad(x1, x0) for (x0,x1) in partition(psi, 2, 1)]
    vcat(psid, psid[end]) #repeat last element so output is same length
end

function get_ra_style(d::TrajLog, aircraft_number::Int64)
    i = aircraft_number
    cas = d["CAS_$i"]
    ra_active = cas[:ra_active]
    target_rate = cas[:ownOutput_target_rate]
    t_style_array = Tuple{Vector{Int64}, ASCIIString}[]
    for (f, s) in RA_STYLE_MAP
        #find times where f is valid and tag it with style s
        times = find(x->f(x[1], x[2]), zip(ra_active, target_rate))
        push!(t_style_array,(times, s))
    end
    t_style_array #vector of tuples.  each tuple = (times::Vector, style::AbstractString)
end

function get_response_style(d::TrajLog, aircraft_number::Int64)
    i = aircraft_number
    pr = get_log(d, "Response", i)

    #stochastic linear case
    if haskey(pr, :response)
        t_style_array = (Vector{Int64}, string)[]

        for (f, s) in RESPONSE_STYLE_MAP
            times = find(f, pr[:response])
            push!(t_style_array,(times, s))
        end
        return t_style_array
    end

    #deterministic PR case
    if haskey(pr, :state) 
        t_style_array = Tuple{Vector{Int64}, ASCIIString}[]

        for (f, s) in RESPONSE_STYLE_MAP
        times = find(f, pr[:state])
        push!(t_style_array,(times, s))
        end
        return t_style_array
    end
end

function trajPlot{T<:AbstractString}(savefiles::Vector{T}; format::Symbol=:TEXPDF)
    map(f->trajPlot(f, format=format), savefiles)
end

function trajPlot(savefile::AbstractString; format::Symbol=:TEXPDF)
    # add suppl info and reload.  This avoids adding suppl info to all files
    add_supplementary(savefile)
    d = trajLoad(savefile)

    outfileroot = getSaveFileRoot(savefile)
    trajPlot(outfileroot, d, format=format)

    savefile
end

function trajPlot(outfileroot::AbstractString, d::TrajLog; format::Symbol=:TEXPDF)
    #workaround, Tikzpictures/lualatex doesn't handle backslashes properly in path
    outfileroot = replace(outfileroot, "\\", "/") 

    td = TikzDocument()
    tps = pgfplotLog(d)

    cap = string(vis_runtype_caps(d),
               vis_sim_caps(d),
               vis_runinfo_caps(d))

    add_to_document!(td, tps, cap)
    plot_tikz(outfileroot, td, format)
    td
end

end #module
