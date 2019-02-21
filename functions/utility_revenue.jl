function utility_revenue_change(bill::Dict, DS::Tariff, transmission::Float64 = 12.07)
        utility_change = Dict{Any,Any}()
        
		if !("grid_energy_savings" in keys(bill["savings"]))
			grid_energy_savings = bill["savings"]["savings_energy_cost_peak"]  + bill["savings"]["savings_energy_cost_valley"] + bill["savings"]["savings_energy_cost_night"]
		    demand_charges = bill["savings"]["savings_demand_charge_peak"]  + bill["savings"]["savings_demand_charge_valley"] + bill["savings"]["savings_demand_charge_night"]
		else
			grid_energy_savings = bill["savings"]["grid_energy_savings"]
			demand_charges = bill["savings"]["demand_charges"]
		end
		
		utility_change["consumer_savings"] = user_savings = -1*( grid_energy_savings + demand_charges + bill["savings"]["street_light"])
        utility_change["withdrawal_charges"] = withdrawn_charges = bill["withdrawn_energy_cost"]
        #Energy Change 
        utility_change["energy_night"] = energy_night = (transmission + SD.e_cost[3][2])*(bill["Balance"]["utility_balance"]["consumer_energy_night"] - bill["Balance"]["utility_balance"]["grid_energy_night"])
        utility_change["energy_valley"] = energy_valley = (transmission + SD.e_cost[2][2])*(bill["Balance"]["utility_balance"]["consumer_energy_valley"] - bill["Balance"]["utility_balance"]["grid_energy_valley"])
        utility_change["energy_peak"] = energy_peak = (transmission + SD.e_cost[1][2])*(bill["Balance"]["utility_balance"]["consumer_energy_peak"] - bill["Balance"]["utility_balance"]["grid_energy_peak"])
        #Demand Change 
        utility_change["demand_night"] = demand_night = (SD.p_cost[3][2])*(bill["Balance"]["utility_balance"]["consumer_demand_night"] - bill["Balance"]["utility_balance"]["grid_demand_night"])
        utility_change["demand_valley"] = demand_valley = (SD.p_cost[2][2])*(bill["Balance"]["utility_balance"]["consumer_demand_valley"] - bill["Balance"]["utility_balance"]["grid_demand_valley"])
        utility_change["demand_peak"] = demand_peak = (SD.p_cost[1][2])*(bill["Balance"]["utility_balance"]["consumer_demand_peak"] - bill["Balance"]["utility_balance"]["grid_demand_peak"])      
        #Totals
        utility_change["losses"] = losses = (user_savings + withdrawn_charges + energy_night + energy_valley + energy_peak + demand_night + demand_valley + demand_peak) 
        bill["utility_change"] = utility_change
end
	
	
function PV_losses(consumer_input::Consumer, system::PVSystem, SD::Tariff; tariff_increase=true)
    
    consumer = deepcopy(consumer_input)
    
	utility_tariff = deepcopy(SD)	
		
	total_losses = Array{Float64,2}(undef,12,consumer.decision_timeframe)
    
    for y in 1:consumer.decision_timeframe
                
        ebalance = annual_energy_balance(consumer, system, print_output=false);
        
        for m in 1:12

            bill = monthly_bill(ebalance[m], consumer, SD = utility_tariff, print_output=false)

            total_losses[m,y] = bill["utility_change"]["losses"]

        end
        
        tariff_increase ? increase_tariff!(consumer) : true
		tariff_increase ? increase_tariff!(utility_tariff) : true	
        
    end

    return total_losses
        
end