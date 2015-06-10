include("../defines/define_save.jl")

#dependencies
include("label270.jl")

function add_label270{T<:String}(files::Vector{T})

  for f in files

    d = trajLoad(f)

    ra_names = sv_simlog_names(d, "ra")

    b_label_exists = any(x -> x == "label270", ra_names)
    b_label_short_exists = any(x -> x == "label270_short", ra_names)

    if b_label_exists && b_label_short_exists
      continue #already processed, nothing to do
    end

    #append field to var_names
    if !b_label_exists
      push!(d["sim_log"]["var_names"]["ra"], "label270")
      push!(d["sim_log"]["var_units"]["ra"], "text")
    end

    if !b_label_short_exists
      push!(d["sim_log"]["var_names"]["ra"], "label270_short")
      push!(d["sim_log"]["var_units"]["ra"], "text")
    end

    cr_index = findfirst(x -> x == "crossing", ra_names)
    cc_index = findfirst(x -> x == "cc", ra_names)
    vc_index = findfirst(x -> x == "vc", ra_names)
    ua_index = findfirst(x -> x == "ua", ra_names)
    da_index = findfirst(x -> x == "da", ra_names)

    if any(x -> x == 0, [cr_index, cc_index, vc_index, ua_index, da_index])
      error("add_supplementary: Flags not found!")
    end

    ra_top = d["sim_log"]["ra"]
    num_aircraft = length(ra_top["aircraft"])

    for i = 1:num_aircraft

      ra_i = ra_top["aircraft"][string(i)]
      t_end = length(ra_i["time"])
      prev_label_code = 0 #code at previous change
      code_tm1 = 0 #code at t-1

      for t = 1:t_end

        ra = ra_i["time"][string(t)]
        code = get_code(ra[cc_index], ra[vc_index], ra[ua_index], ra[da_index])
        crossing = ra[cr_index]

        #prev_code is previous different code
        if code != code_tm1
          prev_label_code = code_tm1
        end

        if !b_label_exists
          label = get_textual_label(code, prev_label_code, crossing, true)
          push!(ra, label) #append to data vector
        end

        if !b_label_short_exists
          label_short = get_textual_label(code, prev_label_code, crossing, false)
          push!(ra, label_short) #append to data vector
        end

        code_tm1 = code
      end
    end

    trajSave(getSaveFileRoot(f), d, compress = isCompressedSave(f))
  end
end

add_supplementary(file::String) = add_supplementary([file])

function add_supplementary{T<:String}(files::Vector{T})

  add_label270(files)
end

