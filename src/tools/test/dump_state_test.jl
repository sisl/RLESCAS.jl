using RLESCAS
using SISLES
using DataFrames

CCAS_PATH = Pkg.dir("CCAS")
LIBCAS = joinpath(CCAS_PATH, "libcas0.10.3/lib/libcas.dll")
LIBCAS_CONFIG = joinpath(CCAS_PATH, "libcas0.10.3/parameters/0.10.3.standard.r15.tcas.xa.config.txt")

sim_params = defineSimParams(; libcas=LIBCAS, libcas_config=LIBCAS_CONFIG)
sim = defineSim(sim_params)

SISLES.GenerativeModel.initialize(sim)

#include("dump_sim_state.jl")
#d=extract_state(DataFrame, sim)
