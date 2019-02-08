function print_base(energy_totals::Dict)

                println("month", " ", "consumer_energy", " ", 
                                "PV_energy", " ", 
                                "injection_grid", " ",  
                                "grid_energy", " ",
                                "global_allowance", " ", 
                                "allowance", " ",
                                "withdrawn_energy", " ", 
                                "utility_supplied_energy", " ",
                                "carryover"," ",
                                "peak_power", " ",
                                "peak_demand") 
        
        
        for i in 1:12
    
                println(i, " ",round(energy_totals[i]["consumer_energy"], digits=2), " ", 
                                round(energy_totals[i]["PV_energy"], digits =2), " ", 
                                round(energy_totals[i]["injection_grid"], digits = 2), " ",
                                round(energy_totals[i]["grid_energy"], digits=2), " ",
                                round(energy_totals[i]["global_allowance"], digits=2), " ",
                                round(energy_totals[i]["allowance"],digits=2), " ",
                                round(energy_totals[i]["withdrawn_energy"],digits=2), " ",
                                round(energy_totals[i]["utility_supplied_energy"], digits=2), " ",
                                round(energy_totals[i]["carry_over"], digits=2), " ",
                                round(energy_totals[i]["peak_power"], digits=2), " ",
                                round(energy_totals[i]["peak_demand"], digits=2)
                                ) 
        
     end

end

function print_TMT(energy_totals::Dict)

                println("month", " | ","consumer_energy_peak", " ",
                                "consumer_energy_valley", " ",
                                "consumer_energy_night", " ",
                                " | ",
                                "PV_energy", " ", 
                                "total_injection", " ",  
								"global_allowance", " ", 
                                "withdrawn_energy", " ", 
                                " | ",        
                                "grid_energy_peak", " ",
                                "grid_energy_valley", " ",
                                "grid_energy_night", " ",        
                                " | ",                     
                                "global_generation"," ", 
                                "global_withdrawal", " ",
                                "carry_over", " ",
								" | ",
								"peak_power_peak", " ",
                                "peak_power_valley", " ",
                                "peak_power_night", " ", 
                                " | ",        
                                "peak_demand_peak", " ",
                                "peak_demand_valley", " ",
                                "peak_demand_night", " ",        
                                " | ",) 
    
     for i in 1:12 
                println(i," | ",round(energy_totals[i]["consumer_energy_peak"], digits=2), " ",
                                round(energy_totals[i]["consumer_energy_valley"], digits=2), " ",
                                round(energy_totals[i]["consumer_energy_night"], digits=2), " ",
                                " | ",
                                round(energy_totals[i]["PV_energy"], digits =2), " ", 
                                round(energy_totals[i]["total_injection"], digits = 2), " ",
								round(energy_totals[i]["global_allowance"], digits=2), " ",
                                round(energy_totals[i]["withdrawn_energy"],digits=2), " ", 
                                " | ",
                                round(energy_totals[i]["grid_energy_peak"], digits=2), " ",
                                round(energy_totals[i]["grid_energy_valley"], digits=2), " ",
                                round(energy_totals[i]["grid_energy_night"], digits=2), " ",                            
                                " | ",
                                round(energy_totals[i]["global_generation"], digits=2)," ", 
                                round(energy_totals[i]["global_withdrawal"], digits=2), " ",
                                round(energy_totals[i]["carry_over"], digits=2), " ",
								" | ",
								round(energy_totals[i]["peak_power_peak"], digits=2), " ",
                                round(energy_totals[i]["peak_power_valley"], digits=2), " ",
                                round(energy_totals[i]["peak_power_night"], digits=2), " ", 
                                " | ",      
                                round(energy_totals[i]["peak_demand_peak"], digits=2), " ",
                                round(energy_totals[i]["peak_demand_valley"], digits=2), " ",
                                round(energy_totals[i]["peak_demand_night"], digits=2), " ",) 
        end
end
    
# Billings printout    
    
function print_TMT_bills()
        
            println(round(bill["grid_energy_cost_peak"], digits=2), " ",
                    round(bill["grid_energy_cost_valley"], digits=2), " ",
                    round(bill["grid_energy_cost_night"], digits=2), " ",
                    " | ",
                    round(bill["grid_demand_cost_peak"], digits=2), " ",
                    round(bill["grid_demand_cost_valley"], digits=2), " ",
                    round(bill["grid_demand_cost_night"], digits=2), " ",   
                    " | ",        
                    round(bill["withdrawn_energy_cost"], digits =2), " ",
                    " | ",
                    round(bill["savings_energy_cost_peak"], digits=2)," ",
                    round(bill["savings_energy_cost_valley"], digits=2)," ",
                    round(bill["savings_energy_cost_night"], digits=2)," ",
                    " | ",
                    round(bill["savings_demand_cost_peak"], digits=2)," ",
                    round(bill["savings_demand_cost_valley"], digits=2)," ",
                    round(bill["savings_demand_cost_night"], digits=2))        
                            
           
    
end

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

function plot_bill(bill1::Dict, bill2::Dict, fields::Array{String})
    cum_sum1 = Array{Float64,1}(undef, 12)
    cum_sum2 = Array{Float64,1}(undef, 12)
    for i in 1:length(fields)
        var1 = [bill1[m]["$(fields[i])"] for m in 1:12]
        bar(collect(1:12) .- 0.03, bottom = cum_sum1, var1, color = cpalette10[i], edgecolor = "black", linewidth = 0.3, label="$(fields[i])", align="edge", width= -0.4)
        cum_sum1 += var1
        var2 = [bill2[m]["$(fields[i])"] for m in 1:12]
        bar(collect(1:12) .+ 0.03, bottom = cum_sum2, var2, color = cpalette10[i], edgecolor = "black", linewidth = 0.3, align="edge", width= 0.4)
        cum_sum2 += var2
    end
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    xticks(collect(1:12));
    xlabel("Month")
    ylabel("Total Bill [Colones]")
end


function plot_savings(bill::Dict)
	cum_sum = Array{Float64,1}(undef, 12)
	for i in keys(bill[1]["savings"])
		var = [bill[m]["savings"][i] for m in 1:12]
		bar(collect(1:12), bottom = cum_sum, var, label=i)   
		cum_sum += var
	end
	var1 = [bill[m]["withdrawn_energy_cost"] for m in 1:12]
	bar(collect(1:12), -1*var1, label="withdrawn_energy_cost")   
	legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
	xticks(collect(1:12));
	xlabel("Month")
	ylabel("Total Bill Savings [Colones]")
	axhline(0, color="black", lw=0.6)
end