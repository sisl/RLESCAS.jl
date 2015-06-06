

function renamefiles{T<:String}(filenames::Vector{T}, searchreplaces::(String, String)...)
  # The batch version of renamefile

  map(f -> renamefile(f, searchreplaces...), filenames)
end

function renamefile(srcname::String, searchreplaces::(String, String)...)
  # Takes the input filename, performs all the string search and replaces (in order passed in)
  # then renames the file to the new name

  dstname = srcname

  for (s, r) in searchreplaces
    dstname = replace(dstname, s, r)
  end

  # Don't rename if no effect
  if dstname != srcname
    mv(srcname, dstname)
  end

  return dstname
end
