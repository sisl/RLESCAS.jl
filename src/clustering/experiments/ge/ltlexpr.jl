push!(LOAD_PATH, "../src")

using GrammaticalEvolution
import GrammaticalEvolution.evaluate!

include("RNGWrapper.jl")
using RNGWrapper

include("ExamplePopulation.jl")

# action for creating
convert_number(lst) = float(join(lst))

const NFEATURES = 70
const TMAX = 50

function create_grammar()
  @grammar grammar begin
    start = bin

    bin = and | or | not | lte | bin_feat | always | eventually
    and = Expr(:&&, bin, bin)
    or = Expr(:||, bin, bin)
    not = Expr(:call, :!, bin)
    lte = Expr(:call, :<=, real_feat, real_number) | Expr(:call, :<=, real_feat, real_feat) | Expr(:call, :<=, real_number, real_feat)
    bin_feat = Expr(:call, :get_feat, bin_feat_id, t)
    always = Expr(:call, :all, bin_vec) #globally
    eventually = Expr(:call, :any, bin_vec) #eventually

    bin_vec = vec_and | vec_or | vec_not | vec_lte
    vec_and = Expr(:call, :&, bin_vec, bin_vec)
    vec_or = Expr(:call, :|, bin_vec, bin_vec)
    vec_not = Expr(:call, :!, bin_vec)
    vec_lte = Expr(:call, :.<=, real_feat_vec, real_number) | Expr(:call, :.<=, real_feat_vec, real_feat_vec) | Expr(:call, :<=, real_number, real_feat_vec)

    real_feat = Expr(:call, :get_feat, real_feat_id, t) #:(d[t, real_feat_id])
    bin_feat = Expr(:call, :get_feat, bin_feat_id, t) #:(d[t, real_feat_id])
    real_feat_vec = Expr(:call, :get_feat, real_feat_id) #:(vec(d[:, real_feat_id]))
    bin_feat_vec = Expr(:call, :get_feat, bin_feat_id) #:(vec(d[:, bin_feat_id]))

    real_feat_id = 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 22 | 26 | 27 | 28 | 29 | 33 | 34 | 35 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 57 | 61 | 62 | 63 | 64 | 68 | 69 | 70
    bin_feat_id = 1 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 23 | 24 | 25 | 30 | 31 | 32 | 36 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 65 | 66 | 67

    real_number[convert_number] = digit + '.' + digit
    digit = 0:9
    t = 1:50
  end

  return grammar
end

#=
function create_grammar()
  @grammar grammar begin
    start = bin

    bin = and | or | not | lte | bin_feat | always | eventually
    and = :(bin && bin)
    or = :(bin || bin)
    not = :(!bin)
    lte = :(real_feat <= real_number) | :(real_feat <= real_feat) | :(real_number <= real_feat)
    bin_feat = :(get_feat(bin_feat_id, t))
    always = :(G(bin_vec)) #always / global
    eventually = :(F(bin_vec)) #eventually / future

    bin_vec = vec_and | vec_or | vec_not | vec_lte
    vec_and = :(bin_vec && bin_vec)
    vec_or = :(bin_vec || bin_vec)
    vec_not = :(!bin_vec)
    vec_lte = :(real_feat_vec .<= real_number) | :(real_feat_vec .<= real_feat_vec) | :(real_number .<= real_feat_vec)

    real_feat = :(d[t, real_feat_id])
    bin_feat = :(d[t, real_feat_id])
    real_feat_vec = :(vec(d[:, real_feat_id]))
    bin_feat_vec = :(vec(d[:, bin_feat_id]))

    real_feat_id = 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 22 | 26 | 27 | 28 | 29 | 33 | 34 | 35 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 57 | 61 | 62 | 63 | 64 | 68 | 69 | 70
    bin_feat_id = 1 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 23 | 24 | 25 | 30 | 31 | 32 | 36 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 65 | 66 | 67

    real_number[convert_number] = digit + '.' + digit
    digit = 0:9
    t = 1:50
  end

  return grammar
end
=#

function GrammaticalEvolution.evaluate!(grammar::Grammar, ind::ExampleIndividual)
  fitness = Float64[]

  try
    ind.code = transform(grammar, ind)
    @eval fn(d) = $(ind.code)
  catch e
    #println("exception = $e")
    #@show ind.code
    ind.fitness = Inf
    return
  end

  #=
  for x=0:10
    for y=0:10
      value = fn(x, y)
      diff = (value - gt(x, y)).^2
      if !isnan(diff) && diff > 0
        insert!(fitness, length(fitness)+1, sqrt(diff))
      elseif diff == 0
        insert!(fitness, length(fitness)+1, 0)
      end
    end
  end
  =#

  ind.fitness = 1.0 #0.001*length(string(ind.code))
end

function main(n::Int)
  rsg = RSG(2, 2)
  set_global(rsg)

  # our grammar
  grammar = create_grammar()

  # create population
  pop = ExamplePopulation(500, 200)

  fitness = Inf
  generation = 1
  while generation < n
    # generate a new population (based off of fitness)
    pop = generate(grammar, pop, 0.1, 0.2, 0.2)

    # population is sorted, so first entry it the best
    fitness = pop[1].fitness
    println("generation: $generation, max fitness=$fitness, code=$(pop[1].code)")
    generation += 1
  end
  return pop[1]
end
