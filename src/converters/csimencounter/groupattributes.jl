include("define_save.jl") #trajLoad

function groupattributes(files::Vector{String}, getlabel::Function, getx::Function, gety::Function)

  outdict = Dict{String, Vector{(Float64, Vector{Float64})}}()

  M = Array(Any, length(files), 3) #number of files by L,x,y

  for (i, f) in enumerate(files)

    d = trajLoad(f)
    M[i, :] = [getlabel(d), getx(d), gety(d)] #each row is L, x, y
  end

  for (L, L_inds) in groupbycol(M, 1)

    Mx = M[L_inds, :]

    xyvecs = map(groupbycol(Mx, 2)) do tup #vector of (x, yvec)
      x, xinds = tup

      return (float64(x), float64(Mx[xinds, 3])) #convert to float for plotting
    end

    sort!(xyvecs, by = v -> v[1]) #sort the x's of easier plotting

    outdict[L] = xyvecs
  end

  return outdict
end

function groupbycol(M::Array{Any, 2}, col::Int64)
  #Looks at all the entries in column 'col' of M.  For each unique entry, return a list of row indices

  labels = unique(M[:, col])
  inds = map(l -> find(x -> x == l, M[:, col]), labels)

  return zip(labels, inds)
end
