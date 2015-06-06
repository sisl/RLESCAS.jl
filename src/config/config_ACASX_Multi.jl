using SISLES
using SISLES.GenerativeModel

function defineSimParams(;
                         nmac_r::Float64 = 500.0,
                         nmac_h::Float64 = 100.0,
                         max_steps::Int64 = 50,
                         num_aircraft::Int64 = 3,
                         encounter_seed::Uint64 = uint64(0),
                         encounterModel::Symbol = :StarDBN, #{:PairwiseCorrAEMDBN, :StarDBN}
                         pilotResponseModel::Symbol = :ICAO_all, #:SimplePR, :StochasticLinear, :FiveVsNone, :ICAO_all
                         end_on_nmac::Bool = true,
                         encounter_file::String = Pkg.dir("SISLES/src/Encounter/CorrAEMImpl/params/cor.txt"),
                         quant::Int64 = 25,
                         #libcas::String = Pkg.dir("CCAS/libcas0.8.6/lib/libcas"),
                         #libcas_config::String = Pkg.dir("CCAS/libcas0.8.6/parameters/0.8.5.standard.r13.xa.config.txt")
                         #libcas::String = Pkg.dir("CCAS/libcas0.9.0/lib/libcas"),
                         #libcas_config::String = Pkg.dir("CCAS/libcas0.9.0/parameters/0.9.0.r14.rev2_3_4candidate07_active.config.txt")
                         libcas::String = Pkg.dir("CCAS/libcas0.9.2/lib/libcas"),
                         libcas_config::String = Pkg.dir("CCAS/libcas0.9.2/parameters/0.9.2.r14.rev3_7candidate08_active.config.txt")
                         )
  p = ACASX_Multi_params()

  p.nmac_r = nmac_r
  p.nmac_h = nmac_h
  p.max_steps = max_steps
  p.num_aircraft = num_aircraft
  p.encounter_seed = encounter_seed
  p.encounterModel = encounterModel
  p.pilotResponseModel = pilotResponseModel
  p.end_on_nmac = end_on_nmac
  p.encounter_file = encounter_file
  p.quant = quant
  p.libcas = libcas
  p.libcas_config = libcas_config

  return p
end

defineSim(p::ACASX_Multi_params) = ACASX_Multi(p)
