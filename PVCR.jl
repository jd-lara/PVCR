using DelimitedFiles
using PyPlot
using Distributions
using DataFrames
using CSV


include("types/tariffs.jl")
include("types/consumers.jl")
include("types/financials.jl")
include("types/pvsystems.jl")

include("functions/printing_results.jl")
include("functions/balance_energy.jl")
include("functions/consumer.jl")
include("functions/billing.jl")
include("functions/financials.jl")
include("functions/pvsystem.jl")
include("functions/depictions.jl")
include("functions/tariffs_hist.jl")

include("data/tariff_data.jl")
include("data/pvsystem_data.jl")
include("data/consumer_data.jl");