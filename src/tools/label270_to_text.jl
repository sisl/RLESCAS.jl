include("../defines/define_save.jl")

label270_to_text{T<:String}(infiles::Vector{T}) = pmap(label270_to_text, infiles)

function label270_to_text(infile::String)
  d = trajLoad(infile)

  ra_names = d["sim_log"]["var_names"]["ra"]

  label_index = findfirst(x -> x == "label270", ra_names)

  if label_index == 0
    error("Field label270 not found")
  end

  ra_top = d["sim_log"]["ra"]
  num_aircraft = length(ra_top["aircraft"])

  outfileroot = getSaveFileRoot(infile)
  outfile = string(outfileroot,"_label270.txt")
  f = open(outfile,"w")

  for i = 1:num_aircraft
    ra_i = ra_top["aircraft"][string(i)]
    t_end = length(ra_i["time"])

    println(f,"Aircraft $i")

    label_tm1 = ""
    for t = 1:t_end
      label_t = ra_i["time"][string(t)][label_index]::String

      if label_t != label_tm1 #only output on change
        println(f, "$(t-1) \t\t $(label_t)")
      end

      label_tm1 = label_t
    end

    println(f, "\n\n")
  end

  close(f)
end
