using RunCases

function extract_params!(paramObj, case::Case, key::String)
  #assumes format of key is: "key.field"

  for (k, v) in case
    k_ = split(k, '.')

    if length(k_) < 2
      warn("extract_params!::dot separator not found in $k")
    end

    if k_[1] == key
      if isdefined(paramObj, symbol(k_[2]))
        paramObj.(symbol(k_[2])) = v
      else
        warn("$(k_[2]) is not a member of type $(typeof(paramObj))")
      end
    end
  end

  return paramObj
end
