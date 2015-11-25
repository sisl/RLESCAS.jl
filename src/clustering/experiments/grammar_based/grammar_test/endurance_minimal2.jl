
try
  srand(0)
  for i = 1:100000
    r1, r2 = rand(2)
    code = Expr(:comparison, r1, :<, r2)
    println("$i: code=$(string(code))")
    @eval f() = $code
    f()
  end
catch e
  println(e)
end
