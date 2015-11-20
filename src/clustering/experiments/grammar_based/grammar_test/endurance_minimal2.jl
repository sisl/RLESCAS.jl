function to_function(code::Expr)
  @eval f() = $code
  return f
end

function get_code()
  r1 = rand()
  r2 = rand()
  Expr(:comparison, r1, :<, r2)
end

using Debug
@debug function script1()
  srand(0)
  for i = 1:100000
    code = "nothing"
    try
      code = get_code()
      f = to_function(code)
      f()
    catch e
      @bp
      println(e)
    end
    println("$i: code=$(string(code))")
  end
end
