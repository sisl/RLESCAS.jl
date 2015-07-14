using MDP
using MCTSdpw
using CPUTime

using Base.Test

function directSample(model::TransitionModel, p::Params, policy::Policy)

  reward, action_seq = simulate(model, p, policy, verbose=true)

  return reward, action_seq
end

function directSample(init::Function, policy::Policy,
                       nsamples::Int; maxtime_s::Float64=typemax(Float64))

  starttime_us = CPUtime_us()

  #random policy
  rewards = Array(Float64, 0) #TODO: try to find a way to preallocate
  action_seqs = Array(Vector{Action}, 0)

  i = 1
  while i <= nsamples
    model, p = init(i)
    rewards_i,action_seqs_i = simulate(model, p, policy, verbose=true)
    push!(rewards, rewards_i)
    push!(action_seqs, action_seqs_i)

    if CPUtime_us() - starttime_us > maxtime_s * 1e6
      break
    end

    i += 1
  end

  return rewards, action_seqs, i
end

function runMCTS(dpw::DPW)

  mcts_reward, action_seq = simulate(dpw.f.model, dpw, selectAction, verbose=true)

  return mcts_reward, action_seq
end

type ActionSequence <: Params
  action_seq::Array{Action, 1}
  index::Int64
  ActionSequence{A <: Action}(action_seq::Array{A, 1}) = new(action_seq, 1)
end

function actionSequencePolicy(al::ActionSequence, s::State)
  action = al.action_seq[al.index]
  al.index += 1

  return action
end

function playSequence{A <: Action}(model::TransitionModel, action_seq::Array{A, 1})

  reward, action_seq2 = directSample(model, ActionSequence(action_seq), actionSequencePolicy)

  @test action_seq == action_seq2 #check replay

  return reward
end
