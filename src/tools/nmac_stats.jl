include("../helpers/save_helpers.jl")

const NMAC_STATS_ROUND_NDECIMALS = 2

function nmac_stats(infiles::Vector{String}, txtfile::String = "nmac_stats.txt")

  stats = Dict{String,Any}()

  for file = infiles

    d = trajLoad(file)
    run_type = d["run_type"]

    if !haskey(stats, run_type)
      stats[run_type] = Dict{String,Any}()
      stats[run_type]["nmac_count"] = int64(0)
      stats[run_type]["nmac_encs_rewards"] = (Int64, Float64)[]
      stats[run_type]["total_count"] = int64(0)
    end

    @show file

    if sv_nmac(d) #nmac occurred

      #increment count
      stats[run_type]["nmac_count"] += 1

      enc_id, enctype = sv_encounter_id(d)

      #add encounter to list
      if enctype != "invalid"
        push!(stats[run_type]["nmac_encs_rewards"],
              (enc_id, sv_reward(d)))
      else
        error("nmac_stats: Invalid encounter id")
      end
    end

    #increment total_count
    stats[run_type]["total_count"] += 1
  end

  #open file
  f = open(txtfile, "w")

  #sort the vectors
  for run_type = keys(stats)

    enc_rewards = stats[run_type]["nmac_encs_rewards"]
    sort!(enc_rewards, by = x -> x[2], rev = true)
    sorted_ids = [tup[1] for tup in enc_rewards]
    sorted_rewards = [tup[2] for tup in enc_rewards]

    if isopen(f)
      println(f, "run type=$run_type")
      println(f, "nmac count=$(stats[run_type]["nmac_count"])")
      println(f, "total count=$(stats[run_type]["total_count"])")
      println(f, "sorted nmac ids=$(sorted_ids)")
      println(f, "sorted nmac rewards=$(round(sorted_rewards, NMAC_STATS_ROUND_NDECIMALS))")
      println(f, "")
    end

  end

  close(f)

  return stats
end
