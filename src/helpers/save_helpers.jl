sv_simlog_names(d::SaveDict, field::String) = d["sim_log"]["var_names"][field]

sv_simlog_units(d::SaveDict, field::String) = d["sim_log"]["var_units"][field]

function sv_simlog_units(d::SaveDict, field::String, vname::String)

  sv_simlog_units(d, field)[sv_lookup_id(d, field, vname)]
end

function sv_simlog_data(d::SaveDict, field::String, aircraft_id::Int64, vname::String)

  sv_simlog_data(d, field, aircraft_id, sv_lookup_id(d, field, vname))
end

function sv_simlog_data(d::SaveDict, field::String, aircraft_id::Int64, var_id::Int64)

  d["sim_log"][field]["aircraft"]["$(aircraft_id)"][var_id]
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64)

  sv_simlog_tdata(d, field, aircraft_id, sorted_times(d, field, aircraft_id))
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, time::Int64)

  d["sim_log"][field]["aircraft"]["$aircraft_id"]["time"]["$time"]
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, time::Int64, vname::String)

  sv_simlog_tdata(d, field, aircraft_id, time, sv_lookup_id(d, field, vname))
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, time::Int64, var_id::Int64)

  d["sim_log"][field]["aircraft"]["$aircraft_id"]["time"]["$time"][var_id]
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, times::Vector)

  times = convert(Vector{Int64}, times) #allows [] syntax on function call

  if isempty(times)
    times = sorted_times(d, field, aircraft_id)
  end

  return [sv_simlog_tdata(d,field,aircraft_id, t) for t=times]
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, times::Vector, vname::String)

  sv_simlog_tdata(d, field, aircraft_id, times, sv_lookup_id(d, field, vname))
end

function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, times::Vector, vid::Int64)

  times = convert(Vector{Int64}, times) #allows [] syntax on function call

  if isempty(times)
    times = sorted_times(d, field, aircraft_id)
  end

  return [sv_simlog_tdata(d, field, aircraft_id, t, vid) for t = times]
end

function sv_simlog_tdata_f(d::SaveDict, field::String, aircraft_id::Int64, time::Int64, vid::Int64)

  convert(Float64, sv_simlog_tdata(d, field, aircraft_id, time, vid))
end

function sv_simlog_tdata_f(d::SaveDict, field::String, aircraft_id::Int64, times::Vector, vid::Int64)

  convert(Vector{Float64}, sv_simlog_tdata(d, field, aircraft_id, times, vid))
end

function sv_lookup_id(d::SaveDict, field::String, vname::String; noerrors::Bool = false)

  i = findfirst(x->x == vname, sv_simlog_names(d, field))

  if !noerrors && i == 0
    error("get_id::variable name not found: $vname")
  end

  return i
end

function sorted_times(d::SaveDict, field::String, aircraft_id::Int64)

  if haskey(d["sim_log"][field]["aircraft"]["$(aircraft_id)"], "time")

    ts = collect(keys(d["sim_log"][field]["aircraft"]["$(aircraft_id)"]["time"]))
    ts = int(ts)
    sort!(ts)

  else

    ts = 0 #flag for time field not found

  end

  return ts
end

sv_num_aircraft(d::SaveDict, field::String = "wm") = length(d["sim_log"][field]["aircraft"])

sortByTime(d::SimLogDict) = sort(collect(d), by = x -> int64(x[1]))

sv_run_type(d::SaveDict) = d["run_type"]

sv_reward(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "reward")]

sv_nmac(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "nmac")]

sv_hmd(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "hmd")]

sv_vmd(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "vmd")]

function sv_md_time(d::SaveDict)
  t_index = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "md_time")] #md_time is the index
  sv_simlog_tdata(d, "wm", 1, t_index, "t")
end

function sv_encounter_id(d::SaveDict)

  enc = -1
  enctype = "invalid"

  if haskey(d["sim_params"]["data"], "encounter_number")
    enc = Obj2Dict.to_obj(d["sim_params"]["data"]["encounter_number"])
    enctype = "encounter_number"
  elseif haskey(d["sim_params"]["data"], "encounter_seed")
    enc = Obj2Dict.to_obj(d["sim_params"]["data"]["encounter_seed"])
    enctype = "encounter_seed"
  else
    warn("sv_encounter_number: Cannot find required fields.")
  end

  return (enc, enctype)
end

is_nmac(file::String) = file |> trajLoad |> sv_nmac

nmacs_only(file::String) = is_nmac(file)
nmacs_only{T<:String}(files::Vector{T}) = filter(is_nmac, files)

function contains_only{T <: String}(filenames::Vector{T}, substr::String)

  filter(f -> contains(f, substr), filenames)
end
