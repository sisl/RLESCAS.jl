module GVTree

export plotTree

using auxfuncs

import MCTSdpw: DPW, State, StateNode

plotTree(dpw::DPW,filename::String) = plotTree(dpw.s,filename)

function plotTree(d::Dict{State,StateNode},filename::String)
  println("Size of sdict: ", length(d))
  outputFile = open(filename,"w")
  write(outputFile,"digraph gvtree {\n")
  for (s,sn) in d
    actions = collect(keys(d[s].a))
    for a in actions
      sp = collect(keys(d[s].a[a].s))[1] #assumes deterministic transition
      @printf(outputFile,"\n%s",hash(s))
      write(outputFile," -> ")
      @printf(outputFile,"%s;",hash(sp))
      @printf(outputFile,"\n%s",hash(sp)) #there are overlaps, but that's ok
      write(outputFile,""" [label="",shape=circle, style=solid, color=black]""")
    end
    @printf(outputFile,"\n%s",hash(s)) #there are overlaps, but that's ok
    write(outputFile,""" [label="",shape=circle, style=solid, color=black]""")
  end
  write(outputFile,"}")
  close(outputFile)
end

end
