using TikzPictures

add_to_document!(d::TikzDocument,tp::TikzPicture,cap::String) = push!(d, tp, caption=cap)

add_to_document!(d::TikzDocument,tps::Array{TikzPicture,1},cap::String) = [add_to_document!(d,tp,cap) for tp in tps]

add_to_document!{Str<:String}(d::TikzDocument,tpsTups::Array{(TikzPicture,Str),1}) = [ add_to_document!(d,tps...) for tps in tpsTups ]

add_to_document!{Str<:String}(d::TikzDocument,tpsTups::Array{(Array{TikzPicture,1},Str),1}) = [ add_to_document!(d,tps...) for tps in tpsTups ]

function use_geometry_package!(p::TikzPicture; margin::Float64 = 0.5, landscape::Bool = false)
  # Adds margin enforcement to pdf file
  # Adds capability for landscape
  # margin in inches
  # landscape false is portrait

  orientation_str = landscape ? ",landscape" : ""

  #prepend geometry package
  p.preamble = "\\usepackage[margin=$(margin)in" * orientation_str * "]{geometry}\n" * p.preamble

  return p
end

function use_aircraftshapes_package!(p::TikzPicture)

  #prepend aircraftshape package
  p.preamble = "\\usepackage{aircraftshapes}\n" * p.preamble

  return p
end
