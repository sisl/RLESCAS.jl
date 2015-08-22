include("../defines/define_save.jl")

function calc_catranges(catlengths::Vector{Int64})

  cl = [1, cumsum(catlengths) + 1]

  return Range[cl[i] : (cl[i+1] - 1) for i = 1 : length(catlengths)]
end

function json_to_csv{T<:String}(savefile::String,
                                categories::Vector{T} = ["command", "sensor", "ra", "ra_detailed", "response",
                                                       "adm", "wm"])

  d = trajLoad(savefile)

  catlengths = Int64[length(sv_simlog_names(d, c)) for c in categories]
  catranges = calc_catranges(catlengths)
  t_end = maximum([length(sorted_times(d, c, 1)) for c in categories])
  num_aircraft = sv_num_aircraft(d)

  header = convert(Array{String}, vcat([map(s->"$c.$s", sv_simlog_names(d, c)) for c = categories]...))
  units = convert(Array{String}, vcat([map(u->"$u", sv_simlog_units(d, c)) for c = categories]...))
  data = Array(Any, t_end, length(header), num_aircraft)
  fill!(data, "n/a")

  for i = 1 : num_aircraft
    for (j, c) = enumerate(categories)
      for t = sorted_times(d, c, i)
        data[t, catranges[j], i] = sv_simlog_tdata(d, c, i, [t])[1]
      end
    end

    fileroot = getSaveFileRoot(savefile)
    filename = string(fileroot, "_aircraft$i.csv")
    f = open(filename, "w")
    writecsv(f, header')
    writecsv(f, units')
    writecsv(f, data[:, :, i])
    close(f)
  end

  return header, units, data
end
