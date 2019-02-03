#=
function print_tariff(tariff::Tariff)
    
    if tariff.category == "Residential"
        x = []
        y = []
        for block in tariff.e_cost 
            x = vcat(x,block[1])
            y = vcat(y, block[2]*ones(length(block[1])))
        end
    
    elseif tariff.category == "Residential"    
    
    end    
        
    
        
    plot(x,y)

end
=#

function plot_bill(bill::Dict, fields::Array{String})
    cum_sum = Array{Float64,1}(undef, 12)
    for i in 1:length(fields)
        var = [bill[m]["$(fields[i])"] for m in 1:12]
        bar(collect(1:12), bottom = cum_sum, var, label="$(fields[i])")
        cum_sum += var
    end
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    xticks(collect(1:12));
    xlabel("Month")
    ylabel("Total Bill [Colones]")
end