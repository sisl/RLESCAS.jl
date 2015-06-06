include("utils/TikzUtils.jl")

using DataStructures

using TikzPictures
import PGFPlots: Plots, Axis, GroupPlot

using Base.Test

function make_fieldmap(num_aircraft::Int)

  M = OrderedDict{String, (Int64, String)}()

  for i = 1:num_aircraft

    i1 = i - 1

    M["State.x.$i1"] = (i, "wm.x")
    M["State.y.$i1"] = (i, "wm.y")
    M["State.h.$i1"] = (i, "wm.z")
    M["State.dx.$i1"] = (i, "wm.vx")
    M["State.dy.$i1"] = (i, "wm.vy")
    M["State.dh.$i1"] = (i, "wm.vz")
    M["Input.own.dz.$i1"] = (i, "ra_detailed.ownInput.dz")
    M["Input.own.z.$i1"] = (i, "ra_detailed.ownInput.z")
    M["Input.own.psi.$i1"] = (i, "ra_detailed.ownInput.psi")
    M["Input.own.h.$i1"] = (i, "ra_detailed.ownInput.h")
    M["Input.own.modes.$i1"] = (i, "ra_detailed.ownInput.modes")

    for j = 1:(num_aircraft - 1)

      j1 = j - 1 #LL uses 0 indexing

      #start from 0, count to n-1, skip self
      lid = getll_id(i1, j1)

      M["Input.intruder.modes.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].modes")
      M["Input.intruder.sr.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].sr")
      M["Input.intruder.chi.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].chi")
      M["Input.intruder.z.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].z")
      M["Input.intruder.cvc.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].cvc")
      M["Input.intruder.vrc.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].vrc")
      M["Input.intruder.vsb.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].vsb")
      M["Input.intruder.equipage.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].equipage")
      M["Input.intruder.protection\_mode.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].protection\_mode")
      M["Input.intruder.quant.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].quant")
      M["Input.intruder.sensitivity\_index.$i1.$lid"] = (i, "ra_detailed.intruderInput[$j].sensitivity\_index")
    end

    M["Output.cc.$i1"] = (i, "ra_detailed.ownOutput.cc")
    M["Output.vc.$i1"] = (i, "ra_detailed.ownOutput.vc")
    M["Output.ua.$i1"] = (i, "ra_detailed.ownOutput.ua")
    M["Output.da.$i1"] = (i, "ra_detailed.ownOutput.da")
    M["Output.target\_rate.$i1"] = (i, "ra_detailed.ownOutput.target\_rate")
    M["Output.turn\_off\_aurals.$i1"] = (i, "ra_detailed.ownOutput.turn\_off\_aurals")
    M["Output.crossing.$i1"] = (i, "ra_detailed.ownOutput.crossing")
    M["Output.alarm.$i1"] = (i, "ra_detailed.ownOutput.alarm")
    M["Output.alert.$i1"] = (i, "ra_detailed.ownOutput.alert")
    M["Output.dh\_min.$i1"] = (i, "ra_detailed.ownOutput.dh\_min")
    M["Output.dh\_max.$i1"] = (i, "ra_detailed.ownOutput.dh\_max")
    M["Output.sensitivity\_index.$i1"] = (i, "ra_detailed.ownOutput.sensitivity\_index")
    M["Output.ddh.$i1"] = (i, "ra_detailed.ownOutput.ddh")

    for j = 1:(num_aircraft - 1)

      j1 = j - 1 #LL uses 0 indexing

      #start from 0, skip self
      lid = getll_id(i1, j1)

      M["Output.intruder.cvc.$i1.$lid"] = (i, "ra_detailed.intruderOutput[$j].cvc")
      M["Output.intruder.vrc.$i1.$lid"] = (i, "ra_detailed.intruderOutput[$j].vrc")
      M["Output.intruder.vsb.$i1.$lid"] = (i, "ra_detailed.intruderOutput[$j].vsb")
      M["Output.intruder.tds.$i1.$lid"] = (i, "ra_detailed.intruderOutput[$j].tds")
      M["Output.intruder.code.$i1.$lid"] = (i, "ra_detailed.intruderOutput[$j].code")
    end
  end

  return M
end

#assumes that both ids start counts at 0
getll_id(listowner_id::Int, item::Int) = item >= listowner_id ? item + 1 : item

function pgfplotField{T <: Real}(llvec::Vector{T}, slvec::Vector{T}, var_name::String = "")

  g = GroupPlot(2, 1, groupStyle = "horizontal sep = 2.2cm, vertical sep = 2.2cm")

  #plot overlay
  plotArray = Plots.Plot[]
  push!(plotArray, Plots.Linear([1:length(llvec)], llvec,
                               style="mark options={color=blue}", mark="*"))
  push!(plotArray, Plots.Linear([1:length(slvec)], slvec,
                               style="mark options={color=red}", mark="*"))
  ax = Axis(plotArray,
            xlabel = "Timestep",
            ylabel = var_name,
            title = "Overlay")
  push!(g, ax)

  #plot difference
  plotArray = Plots.Plot[]
  t_end = min(length(llvec), length(slvec))
  push!(plotArray,Plots.Linear([1:t_end], abs(llvec[1:t_end] - slvec[1:t_end]),
                               style="mark options={color=blue}", mark="*"))
  ax = Axis(plotArray,
            xlabel = "Timestep",
            ylabel = var_name,
            title = "Absolute Difference")
  push!(g, ax)

  tp = PGFPlots.plot(g)
  use_geometry_package!(tp, landscape = false) # portrait

  return tp
end

function getvec(data::Array{Any, 2}, field::String)

  v = []
  headers = data[1, :] # 1st row is headers
  i = findfirst(x -> x == field, headers)

  if i != 0
    try
      v = demote_vectype(data[2:end, i]) #convert to lowest common type
      v = convert(Vector{Float64}, v) #data starts at row 2
    catch
      warn("Cannot convert $field: $(data[2:end, i])")
      v = []
    end
  end

  return v
end

function demote_vectype(v::Vector)
  # Converts vector type to lowest common type amongst elements
  # Fixes the overly general container type problem, i.e., Vector{Any}

  T = promote_type(map(typeof, v)...) #determine the lowest common type

  return convert(Vector{T}, v)
end

import Base.convert
function convert{T <: String}(::Type{Vector{Float64}}, v::Vector{T})

  vv = map(lowercase, v)
  vv = map(parse, vv)
  vv = map(float64, vv)

  return vv
end

function namegen(fileroot::String, indices::Vector{Int64}, extension::String)
  map(i -> string(fileroot, i, extension), indices)
end

function reorder2ll{T <: String}(sislesfiles::Vector{T}, llfile::String;
                                  outfile::String = "reorderedcsv.csv")

  num_aircraft = length(sislesfiles)
  fieldmap = make_fieldmap(num_aircraft)

  lldat = readdlm(llfile)
  llheaders = squeeze(lldat[1, :], 1)

  sldats = map(readcsv, sislesfiles)

  # skip units row
  map!(d -> d[[1,3:end], :], sldats)

  outcsv = Array(Any, size(sldats[1], 1), 0)

  for llfield in llheaders

    if llfield == "time" #skip...
        continue
    end

    if !haskey(fieldmap, llfield)
      error("reorder2ll::No such key! $llfield")
    end

    slfile, slfield = fieldmap[llfield]

    slvec = getvec(sldats[slfile], slfield)

    if isempty(slvec)
      error("$slfield not found in SISLES csv file.")
    end

    outcsv = hcat(outcsv, vcat(slfield, slvec)) #TODO: remove the dynamic growing...
  end

  f = open(outfile, "w")
  writecsv(f, outcsv)
  close(f)

  return outcsv
end

function reorderedcsvdiff(slcsv::String, llcsv::String; thresh::Float64=1.0, use_ll_names::Bool=false)

  fileroot, fileext = splitext(slcsv)
  outfile = string(fileroot, "_emph", fileext)

  sldat = readcsv(slcsv)
  lldat = readdlm(llcsv)
  lldat = lldat[:, 2:end] #skip time col

  if use_ll_names
    sldat[1, :] = lldat[1, :]
  end

  #TODO: avoid the loops
  for c = 1:size(lldat, 2)
    for r = 2:size(lldat, 1) #skip header

      a = abs(lldat[r, c]-sldat[r, c])
      sldat[r, c] = a >= thresh ? a : 0

    end
  end

  f = open(outfile, "w")
  writecsv(f, sldat)
  close(f)

  return sldat
end

function ll_csv_diff{T <: String}(sislesfiles::Vector{T}, llfile::String;
                                  slskipfirst::Bool = false,
                                  outfile::String = "csvdiff.pdf")

  num_aircraft = length(sislesfiles)
  fieldmap = make_fieldmap(num_aircraft)

  lldat = readdlm(llfile)
  sldats = map(readcsv, sislesfiles)

  firstdiff = (String,Int64)[]

  # skip units row
  map!(d -> d[[1,3:end], :], sldats)

  if slskipfirst
    map!(d -> d[[1,3:end], :], sldats)
  end

  td = TikzDocument()

  for (llfield, slfieldtup) in fieldmap

    slfile, slfield = slfieldtup

    llvec = getvec(lldat, llfield)
    slvec = getvec(sldats[slfile], slfield)

    if isempty(llvec) || isempty(slvec)
      llnotfound = isempty(llvec) ? "$llfield not found in LL file." : ""
      slnotfound = isempty(slvec) ? "$slfield not found in SISLES csv file." : ""

      warn("$llnotfound $slnotfound")

      continue
    end

    llfield = replace(llfield, "\_", "\\_")
    slfield = replace(slfield, "\_", "\\_")
    tp = pgfplotField(llvec, slvec, llfield)

    cap = "Variable: $llfield vs. $slfield"

    add_to_document!(td, tp, cap)

    ind = findfirst(x -> x >= 1.0, abs(llvec-slvec))
    push!(firstdiff, (llfield, ind))
  end

  TikzPictures.save(PDF(outfile), td)

  sort!(firstdiff, by = x -> x[2])

  return firstdiff
end
