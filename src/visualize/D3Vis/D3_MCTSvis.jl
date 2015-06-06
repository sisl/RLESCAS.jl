using JSON

push!(LOAD_PATH,joinpath(pwd(),"/../"))
using MDP
import MCTSdpw: DPW, State, Action, StateNode, StateActionNode, StateActionStateNode

function saveSimTree(dpw::DPW,s::State,outfile::String)

  function process(sn::StateNode,Tout)
    for (a,san) in sn.a
      node_ = Dict{ASCIIString, Any}()
      node_["action"] = hash(a)
      node_["N"] = san.n
      node_["Q"] = san.q
      node_["states"] = Dict{ASCIIString, Any}[]

      push!(Tout, node_)

      process(san, node_["states"])
    end
  end

  function process(san::StateActionNode, Tout)
    for (s, sasn) in san.s
      node_ = Dict{ASCIIString, Any}()
      node_["state"] = hash(s)
      node_["N"] = haskey(dpw.s,s) ? dpw.s[s].n : sasn.n
      node_["r"] = sasn.r
      node_["actions"] = Dict{ASCIIString, Any}[]

      push!(Tout, node_)

      if haskey(dpw.s,s)
        process(dpw.s[s], node_["actions"])
      end
    end
  end

  function process{S<:State}(ss::Vector{S}, Tout)
    for s in ss
      node_ = Dict{ASCIIString, Any}()
      node_["state"] = hash(s)
      node_["N"] = dpw.s[s].n
      node_["actions"] = Dict{ASCIIString, Any}[]

      push!(Tout, node_)

      if haskey(dpw.s,s)
        process(dpw.s[s], node_["actions"])
      end
    end
  end

  Tout = Dict{ASCIIString, Any}()
  Tout["name"] = "root"
  Tout["states"] = Dict{ASCIIString, Any}[]

  process([s],Tout["states"])
  f = open(outfile, "w")
  JSON.print(f, Tout, 2)
  close(f)

  return Tout
end
