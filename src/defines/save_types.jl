
type ComputeInfo
  start_time::String  # timestamp at run start
  save_time::String   # timestamp at file save
  machine_name::String  # name of run computer
  compute_time::Float64  # compute time in seconds
end

ComputeInfo() = ComputeInfo("", "", "", -1.0)
