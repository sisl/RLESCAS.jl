include("../defines/define_save.jl")
include("../helpers/save_helpers.jl")

label270_to_text{T<:String}(infiles::Vector{T}) = pmap(label270_to_text, infiles)

function label270_to_text(infile::String)
  d = trajLoad(infile)

  tind = sv_lookup_id(d, "wm", "t")
  lind = sv_lookup_id(d, "ra", "label270")

  outfileroot = getSaveFileRoot(infile)
  outfile = string(outfileroot,"_label270.txt")
  f = open(outfile,"w")

  for i = 1:sv_num_aircraft(d, "ra")
    println(f, "Aircraft $i")

    label_tm1 = ""
    times = sv_simlog_tdata_vid(d, "wm", i, tind)
    labels = sv_simlog_tdata_vid(d, "ra", i, lind)
    for (t, label_t) in zip(times, labels)

      if label_t != label_tm1 #only output on change
        println(f, "$(t) \t\t $(label_t)")
      end

      label_tm1 = label_t
    end

    println(f, "\n\n")
  end

  close(f)
end
