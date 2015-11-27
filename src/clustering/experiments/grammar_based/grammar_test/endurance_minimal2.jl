function get_code()
  r1 = rand()
  r2 = rand()
  (r) -> r < r1 < r2
end

function get_code1()
  r1 = rand()
  r2 = rand()
  ex = Expr(:comparison, :r, :<, r1, :<, r2)
  @eval (r) -> $ex
end

function get_code2()
  r1 = rand()
  r2 = rand()
  @eval (r) -> r < $r1 < $r2
end

function get_code3()
  r1 = rand()
  r2 = rand()
  s = "(r) -> r < $r1 < $r2"
  eval(parse(s))
end

function get_code4()
  r1,r2,r3,r4,r5 = rand(0:9,5)
  q1,q2,q3,q4,q5 = rand(0:9,5)
  ex = Expr(:comparison, :r, :<, quote get_real($r1,$r2,$r3,$r4,$r5) end, :<, quote get_real($q1,$q2,$q3,$q4,$q5) end)
  @eval (r) -> $ex
end

function get_code5()
  module M
  r1 = rand()
  r2 = rand()
  ex = Expr(:comparison, :r, :<, r1, :<, r2)
  @eval f(r) = $ex
  end
  M.f
end

get_real(x,d...) = d |> join |> float

function script1()
  srand(0)
  for i = 1:100000
    code = "nothing"
    try
      f = get_code5()
      f(0.1)
    catch e
      println(e)
      #println(code)
      @assert false
    end
    println("$i: code=$(string(code))")
  end
end

