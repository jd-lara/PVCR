mutable struct PVSystem
    capacity::Float64
    monthly_pu_energy::Array{Float64}
    life_loss::Float64
    cost::Array{Any}
    maintenance::Float64
    time_series::Array{Float64}
end
