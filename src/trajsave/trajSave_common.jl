using RunCases

function extract_params!(paramObj, case::RunCase, key::String)
  #assumes format of key is: "key.field"

  for (k, v) in case
    k_ = split(k, '.')

    if length(k_) < 2
      warn("extract_params!::dot separator not found in $k")
    end

    if k_[1] == key
      paramObj.(symbol(k_[2])) = v
    end
  end

  return paramObj
end
