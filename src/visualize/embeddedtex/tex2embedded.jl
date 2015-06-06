using Base.Test

function resubplot(infile::String, newcols::Int, newrows::Int, subplots::Vector{Int64})

  @test length(subplots) <= newcols * newrows

  fileroot, fileext = splitext(infile)
  outfile = string(fileroot, "_resubplot", fileext)

  s = readall(infile)

  #find group plot command
  m = match(r"\\begin\{groupplot\}\[group style=\{.*group size=\s*(\d)\s*by\s*(\d)\s*\}\]", s)

  if m == nothing
    error("resubplot::Group Plot not found!")
  end

  oldcols, oldrows = int(m.captures)
  coloffset, rowoffset = int(m.offsets)

  part1 = string(s[1:(coloffset - 1)], newcols,
                 s[(coloffset + 1):rowoffset-1], newrows,
                 s[(rowoffset + 1): m.offset + length(m.match)]) #manual regex replace

  transitions = Int64[]
  idx = 1
  while true

    # try matching between groupplots
    m = match(r"(\\nextgroupplot|\\end\{groupplot\})", s, idx)

    if m == nothing
      break;
    end

    push!(transitions, m.offsets[1])
    idx = m.offsets[1] + length(m.captures[1])
  end

  groupplots = String[]
  for (r1, r2) in zip(transitions[1:end - 1], transitions[2:end] - 1)
    push!(groupplots, s[r1:r2])
  end

  # only include the ones in subplots
  part2 = string(groupplots[subplots]...)

  part3 = s[transitions[end]:end]

  f = open(outfile, "w")
  write(f, part1, part2, part3)
  close(f)

  return outfile
end

function tex2embedded(infile::String; scaletext::Bool = true)
  #To use the embedded tikz tex, input it inside a figure
  #\begin{figure}
  #\centering
  #\resizebox{\columnwidth}{!}{%
  #                            \input{fig1.tikz}
  #                            }%
  #\caption{figure1}
  #\label{fig:figure1}
  #\end{figure}

  s = readall(infile)

  begin_matches = eachmatch(r"\\begin\{tikzpicture\}", s)
  end_matches = eachmatch(r"\\end\{tikzpicture\}\n", s)

  if begin_matches == nothing || end_matches == nothing
      error("tex2embedded:tikzpicture not found!")
    end

  #FIXME: this is pretty inefficient
  @test length(collect(begin_matches)) == length(collect(end_matches)) #begin and ends should correspond

  i = 1
  for (b, e) in zip(begin_matches, end_matches)

    b_ind = b.offset
    e_ind = e.offset + length(e.match)

    #FIXME: this is pretty inefficient. does s[b:e] create new substrings?
    m = match(r"(\\begin\{tikzpicture\}[\s\S]*\\end\{tikzpicture\}\n)", s[b_ind:e_ind])

    if m == nothing
      error("tex2embedded::not matched!")
    end

    tikz = m.captures[1]

    if scaletext
      tikz = replace(tikz, "\\begin{tikzpicture}[]", "\\begin{tikzpicture}[transform shape]")
    end

    outfile = string(splitext(infile)[1], "_$i.tikz")
    f = open(outfile, "w")
    write(f, tikz)
    close(f)

    i += 1
  end


end
