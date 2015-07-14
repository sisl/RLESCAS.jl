using JSON
using GZip

using Base.Test

typealias SaveDict Dict{String, Any}

function trajSave(fileroot::String, d::SaveDict; compress::Bool=true)

  if compress
    outfile = string(fileroot, ".json.gz")
    f = GZip.open(outfile, "w")
  else
    outfile = string(fileroot, ".json")
    f = open(outfile, "w")
  end

  JSON.print(f, d)
  close(f)

  return outfile
end

function trajLoad(infile::String)

  if isCompressedSave(infile)
    #compressed
    f = GZip.open(infile, "r")
  elseif isRawSave(infile)
    #raw json
    f = open(infile, "r")
  else
    error("Invalid file type.  Expected .gz or .json extension.")
  end

  d = JSON.parse(f)
  close(f)

  return d
end

function readdirExt(ext::String, dir::String = ".")

  #ext should start with a '.' to be a valid extension
  @test ext[1] == '.'

  files = readdir(dir)
  filter!(f -> splitext(f)[2] == ext, files)

  return String[joinpath(dir, f) for f in files]
end

readdirJSONs(dir::String=".") = readdirExt(".json", dir)

readdirGZs(dir::String=".") = readdirExt(".gz", dir)

readdirSaves(dir::String=".") = vcat(readdirJSONs(dir), readdirGZs(dir))

isRawSave(f::String) = splitext(f)[2] == ".json"

isCompressedSave(f::String) = splitext(f)[2] == ".gz"

isSave(f::String) = isRawSave(f) || isCompressedSave(f)

function getSaveFileRoot(f::String)

  if isCompressedSave(f)
    j = splitext(f)[1] #contains .json, need to split again
    fileroot = splitext(j)[1]
  else #raw save
    fileroot = splitext(f)[1]
  end

  return fileroot
end
