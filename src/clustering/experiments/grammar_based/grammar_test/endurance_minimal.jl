using GrammaticalEvolution

convert_number(lst) = float(join(lst))::Float64

function create_grammar()
  @grammar grammar begin
    start = Expr(:comparison, real_number, :<, real_number)

    #random numbers
    real_number = rand_pos | rand_neg
    rand_pos[convert_number] =  digit + '.' + digit + digit + digit + digit + 'e' + expdigit
    rand_neg[convert_number] =  '-' + digit + '.' + digit + digit + digit + digit + 'e' + expdigit
    digit = 0:9
    expdigit = -4:4
  end
  return grammar
end

function to_function(code::Expr)
  @eval f() = $code
  return f
end

using Debug
@debug function script1()
  srand(0)
  grammar = create_grammar()
  for i = 1:100000
    ind = ExampleIndividual(400, 1000)
    try
      ind.code = transform(grammar, ind)
      f = to_function(ind.code)
      f()
    catch e
      if !isa(e, MaxWrapException)
        @bp
        println(e)
      end
    end
    println("$i: code=$(string(ind.code))")
  end
end
