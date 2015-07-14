
#emulates calling from command line
empty!(ARGS)
push!(ARGS, "config_2ac.ini")
include("../src/mcts.jl")
