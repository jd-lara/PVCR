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

stripChar = (s, r) -> replace(s, Regex("[$r]") => " ")

function plot_bill(bill::Dict, fields::Array{String}, digits::Int64 = 1)
	cum_sum = Array{Float64,1}(undef, 12)
    for i in 1:length(fields)
        var = [bill[m]["$(fields[i])"] for m in 1:12]
        bar(collect(1:12), bottom = cum_sum, var, label=stripChar("$(fields[i])", "_"), edgecolor = "black", linewidth = 0.3)
        cum_sum += var
    end
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    xticks(collect(1:12));
    y_ul = maximum([round(bill[m]["counterfactual_cost"], RoundUp, sigdigits = digits) for m in 1:12])
	xlabel("Month")
    ylabel("Total Bill [Colones]")
	ylim(0,y_ul)
	title("Consumer Monthly Electric Utility Bill Breakdown")
end

function plot_bill(bill1::Dict, bill2::Dict, fields::Array{String}, digits::Int64 = 1)
    cum_sum1 = Array{Float64,1}(undef, 12)
    cum_sum2 = Array{Float64,1}(undef, 12)
    
	for i in 1:length(fields)
        var1 = [bill1[m]["$(fields[i])"] for m in 1:12]
        bar(collect(1:12) .- 0.03, bottom = cum_sum1, var1, color = cpalette10[i], edgecolor = "black", linewidth = 0.3, label=stripChar("$(fields[i])", "_"), align="edge", width= -0.4)
        cum_sum1 += var1
        var2 = [bill2[m]["$(fields[i])"] for m in 1:12]
        bar(collect(1:12) .+ 0.03, bottom = cum_sum2, var2, color = cpalette10[i], edgecolor = "black", linewidth = 0.3, align="edge", width= 0.4)
        cum_sum2 += var2
    end
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    y_ul1 = maximum([round(bill1[m]["counterfactual_cost"], RoundUp, sigdigits = digits) for m in 1:12])
	y_ul2 = maximum([round(bill2[m]["counterfactual_cost"], RoundUp, sigdigits = digits) for m in 1:12])
	xlabel("Month")
    ylabel("Total Bill [Colones]")
	ylim(0,max(y_ul1,y_ul2))
	title("Consumer's Change in Montly Electric Bill")
end


function plot_savings(bill::Dict, digits::Int64 = 1)
	cum_sum = Array{Float64,1}(undef, 12)
	for i in keys(bill[1]["savings"])
		var = [bill[m]["savings"][i] for m in 1:12]
		bar(collect(1:12), bottom = cum_sum, var, label=stripChar(i, "_"), edgecolor = "black", linewidth = 0.3)   
		cum_sum += var
	end
	var1 = [bill[m]["withdrawn_energy_cost"] for m in 1:12]
	bar(collect(1:12), -1*var1, label="withdrawn energy cost", edgecolor = "black", linewidth = 0.3)   
	legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
	xticks(collect(1:12));
	y_ul = maximum([round(bill[m]["counterfactual_cost"], RoundUp, sigdigits = digits) for m in 1:12])
	y_lb = minimum(-1*var1)
	xlabel("Month")
    ylabel("Total Savings [Colones]")
	ylim(y_lb,y_ul)
	axhline(0, color="black", lw=0.6)
	title("Consumer Monthly Electric Utility Bill Savings")
end

function plot_utility_change(bill::Dict, digits::Int64 = 1)
	cum_sum = Array{Float64,1}(undef, 12)
	for i in keys(bill[1]["utility_change"])
		if !(i in ["consumer_savings", "losses"]) 
            var = [bill[m]["utility_change"][i] for m in 1:12]
            sum(var .< 0) > 0  ? @info("Losses for energy displacement") : true
			bar(collect(1:12), bottom = cum_sum, var, label=stripChar(i, "_"), edgecolor = "black", linewidth = 0.3)   
            cum_sum += var
        end
	end
	var1 = [bill[m]["utility_change"]["consumer_savings"] for m in 1:12]
	bar(collect(1:12), var1, label="consumer savings", edgecolor = "black", linewidth = 0.3) 
    var2 = [bill[m]["utility_change"]["losses"] for m in 1:12]
    plot(collect(1:12), var2, label = "net losses", color="red")
	legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
	xticks(collect(1:12));
	y_ul = maximum([round(bill[m]["counterfactual_cost"], RoundUp, sigdigits = digits) for m in 1:12])
    y_lb = minimum(var1)
	xlabel("Month")
    ylabel("Total Change for Utility [Colones]")
	ylim(y_lb,y_ul)
	axhline(0, color="black", lw=0.6)
	title("Utility Monthly Revenue Change")
end