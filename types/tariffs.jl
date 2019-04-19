mutable struct Tariff
    provider::String
    category::String
    e_cost::Array{Any}
    p_cost::Array{Any}
    increase::Float64
    access::Float64
    street_light::Float64
    access_increase::Float64
    behaviour::Array{Float64}
	min_cost::Float64
end


