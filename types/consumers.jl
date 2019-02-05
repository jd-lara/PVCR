abstract type Consumer end

mutable struct Residential <: Consumer
    periods::Float64
    econsumption::Float64 #kWh-month
    growth::Float64
    peak_power::Union{Nothing,Array{Float64}}
    load_curve::Array{Float64}
    tariff::Tariff
    decision_timeframe::Int64
    rate_return::Float64
end

mutable struct CommIndus <: Consumer
    periods::Float64
    econsumption::Float64 #kWh-month
    growth::Float64
    peak_power::Union{Nothing,Array{Float64}}
    load_curve::Array{Float64}
    tariff::Tariff
    decision_timeframe::Int64
    rate_return::Float64
end

mutable struct TMT <: Consumer
    periods::Float64
    econsumption::Float64 #kWh-month
    growth::Float64
    peak_power::Union{Nothing,Array{Float64}}
    load_curve::Array{Float64}
    tariff::Tariff
    decision_timeframe::Int64
    rate_return::Float64
end






