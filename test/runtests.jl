
empty!(ARGS)
push!(ARGS, "config.ini")
include("../src/mcts.jl")
