# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# Created 3/31/2015
# Based on visualization code originally written in Matlab provided by
# Mykel Kochenderfer, mykel@stanford.edu

using Base.Test

#code is an int with 4 digits corresponding to cc,vc,ua,da
function get_textual_label(code::Int,prev_code::Int,crossing::Bool,full::Bool=true)

  if code == 4010
    s = full ? "Climb" : "CL"
  elseif code == 5001
    s = full ? "Descend" : "DS"
  elseif code == 4110
    s = full ? "Climb, Crossing" : "CLX"
  elseif code == 5101
    s = full ? "Descend, Crossing" : "DSX"
  elseif code == 5002
    pc = prev_code
    if (pc==0 || pc==1000 || #if its a new encounter
        pc==6002 || pc==6003 || pc==6004 || pc==6005 || #if following a preventative limit climb
        pc==6020 || pc==6030 || pc==6040 || pc==6050) #if following a preventative limit descent
      s = full ? "Level-off (DNC)" : "LV_DNC"
    else
      s = full ? "Level-off (Weaken)" : "LV_WKN"
    end
  elseif code == 4020
    pc = prev_code
    if (pc==0 || pc==1000 || #if its a new encounter
        pc==6002 || pc==6003 || pc==6004 || pc==6005 || #if following a preventative limit climb
        pc==6020 || pc==6030 || pc==6040 || pc==6050) #if following a preventative limit descent
      s = full ? "Level-off (DND)" : "LV_DND"
    else
      s = full ? "Level-off (Weaken)" : "LV_WKN"
    end
  elseif code == 4210
    s = full ? "Reverse Climb" : "RV_CL"
  elseif code == 5201
    s = full ? "Reverse Descend" : "RV_DS"
  elseif code == 4310
    s =  full ? "Increase Climb" : "CL+"
  elseif code == 5301
    s = full ? "Increase Descend" : "DS+"
  elseif code == 4410
    if crossing
      s = full ? "Maintain Vertical Speed, Crossing" : "MTVSX"
    else
      s = full ? "Maintain Vertical Speed" : "MTVS"
    end
  elseif code == 5401
    if crossing
      s = full ? "Maintain Vertical Speed, Crossing" : "MTVSX"
    else
      s = full ? "Maintain Vertical Speed" : "MTVS"
    end
  elseif code == 6002
    s = full ? "Monitor Vertical Speed (DNC)" : "MOVS_DNC"
  elseif code == 6003
    s = full ? "Monitor Vertical Speed (500)" : "MOVS500"
  elseif code == 6004
    s = full ? "Monitor Vertical Speed (1000)" : "MOVS1000"
  elseif code == 6005
    s = full ? "Monitor Vertical Speed (2000)" : "MOVS2000"
  elseif code == 6020
    s = full ? "Monitor Vertical Speed (DND)" : "MOVS_DND"
  elseif code == 6030
    s = full ? "Monitor Vertical Speed (-500)" : "MOVS-500"
  elseif code == 6040
    s = full ? "Monitor Vertical Speed (-1000)" : "MOVS-1000"
  elseif code == 6050
    s = full ? "Monitor Vertical Speed (-2000)" : "MOVS-2000"
  elseif code == 6422
    s = full ? "Maintain Vertical Speed, MTE ()" : "MTVS_MTE"
  elseif code == 5022
    s = full ? "Level-off, MTE" : "LV_MTE"
  elseif code == 4022
    s = full ? "Multi-Aircraft Encounter (Descending)" : "MTE_DS"
  elseif code == 6022
    s = full ? "Multi-aircraft Encounter" : "MTE"
  elseif code == 1000 || code == 0000
    s = full ? "Clear of Conflict" : "COC"
  else
    s = full ? "N/A ($code)" : "?$code"
  end

  return s
end

function get_code(cc::Int,vc::Int,ua::Int,da::Int)
  dcc = digits(cc)
  dvc = digits(vc)
  dua = digits(ua)
  dda = digits(da)

  @test length(dcc) == length(dvc) == length(dua) == length(dda) == 1

  code = int64(string(dcc[1],dvc[1],dua[1],dda[1]))

  return code
end
