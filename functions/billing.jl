include("taxes.jl")

function monthly_bill(energy_dict::Dict, consumer::Residential; print_output = false)

    bill = Dict{String,Any}()

    grid_energy_cost = 0.0
    counterfactual_cost = 0.0

    for block in consumer.tariff.e_cost
        energy_dict["grid_energy"] > block[1][end] ? grid_energy_cost += block[1][end]*block[2] : grid_energy_cost += (energy_dict["grid_energy"] - block[1][1])*block[2]*(energy_dict["grid_energy"] > block[1][1])
    end

    for block in consumer.tariff.e_cost
        energy_dict["consumer_energy"] > block[1][end] ?  counterfactual_cost += block[1][end]*block[2] :  counterfactual_cost += (energy_dict["consumer_energy"] - block[1][1])*block[2]*(energy_dict["consumer_energy"] > block[1][1])
    end
    
    
    bill["Balance"] = energy_dict;
    
    bill["grid_cost"] = grid_energy_cost
    bill["withdrawn_energy_cost"] = energy_dict["withdrawn_energy"]*consumer.tariff.access

    bill["total_energy_cost"] = grid_energy_cost + bill["withdrawn_energy_cost"]
    bill["street_light"] = street_light(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"], consumer.tariff.street_light)
    bill["VAT"] = VAT(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"], grid_energy_cost + bill["demand_charge"])
    bill["firefighters"] = firefighters(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"], bill["total_energy_cost"] + bill["demand_charge"])
    
    bill["demand_charge"] = consumer.tariff.p_cost[1][2]*energy_dict["peak_demand"]
    bill["counterfactual_demand_charge"] = consumer.tariff.p_cost[1][2]*energy_dict["peak_power"]
        
    bill["total_cost"] = bill["total_energy_cost"] + bill["street_light"] + bill["VAT"] + bill["firefighters"] + bill["demand_charge"]
    
    bill["counterfactual_cost"] = counterfactual_cost + 
                                  street_light(energy_dict["consumer_energy"], consumer.tariff.street_light) + 
                                  VAT(energy_dict["consumer_energy"], counterfactual_cost + bill["counterfactual_demand_charge"]) +
                                  firefighters(energy_dict["consumer_energy"], counterfactual_cost + bill["counterfactual_demand_charge"])
    
    bill["savings"] = bill["counterfactual_cost"] - bill["total_cost"]
        

    if print_output
            println(round(bill["grid_cost"], digits=2), " ",
                    round(bill["withdrawn_energy_cost"], digits =2), " ",
                    round(bill["total_cost"], digits = 2), " ",
                    " | ",
                    round(bill["counterfactual_cost"], digits=2)," ",
                    round( bill["savings"], digits=2),)
    end

    return bill

end

function monthly_bill(energy_dict::Dict, consumer::CommIndus; print_output = false)

    bill = Dict{String,Any}()

    grid_energy_cost = 0.0
    demand_charges = 0.0
    counterfactual_energy_cost = 0.0
    counterfactual_demand_cost = 0.0
    
    #energy costs
    
    if energy_dict["grid_energy"] <= consumer.tariff.e_cost[1][1][end]
        grid_energy_cost = energy_dict["grid_energy"]*consumer.tariff.e_cost[1][2]
    elseif energy_dict["grid_energy"] > consumer.tariff.e_cost[1][1][end]
        grid_energy_cost = energy_dict["grid_energy"]*consumer.tariff.e_cost[2][2]
    end
 
    if energy_dict["consumer_energy"] <= consumer.tariff.e_cost[1][1][end]
        counterfactual_energy_cost = energy_dict["consumer_energy"]*consumer.tariff.e_cost[1][2]
    elseif energy_dict["consumer_energy"] > consumer.tariff.e_cost[1][1][end]
        counterfactual_energy_cost = energy_dict["consumer_energy"]*consumer.tariff.e_cost[2][2]
    end    
    
    if !(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"] <= 3000)        
            
        #demand charges
        if energy_dict["peak_demand"] <= consumer.tariff.p_cost[1][1][end]
            demand_charges = consumer.tariff.p_cost[1][2]
        elseif energy_dict["peak_demand"] > consumer.tariff.p_cost[1][1][end]
            demand_charges = consumer.tariff.p_cost[2][2]*energy_dict["peak_demand"]
        end
    end
                
    if !(energy_dict["consumer_energy"] <= 3000)
                    
        if energy_dict["peak_power"] <= consumer.tariff.p_cost[1][1][end]
            counterfactual_demand_cost = consumer.tariff.p_cost[1][2]
        elseif energy_dict["peak_power"] > consumer.tariff.p_cost[1][1][end]
            counterfactual_demand_cost = consumer.tariff.p_cost[2][2]*energy_dict["peak_power"]
        end
    
    end

    bill["Balance"] = energy_dict;
    bill["grid_cost"] = grid_energy_cost
    bill["withdrawn_energy_cost"] = energy_dict["withdrawn_energy"]*consumer.tariff.access
    bill["total_energy_cost"] = grid_energy_cost + bill["withdrawn_energy_cost"]
    bill["demand_cost"] = demand_charges 
                    
    bill["street_light"] = street_light(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"], consumer.tariff.street_light)
    bill["VAT"] = VAT(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"], grid_energy_cost+bill["demand_cost"])
    bill["firefighters"] = firefighters(energy_dict["grid_energy"]+energy_dict["withdrawn_energy"], bill["total_energy_cost"]+bill["demand_cost"])
    
    bill["total_cost"] = bill["total_energy_cost"] +  bill["demand_cost"] + bill["street_light"] + bill["VAT"] + bill["firefighters"]
    
    bill["counterfactual_energy_cost"] = counterfactual_energy_cost
    bill["counterfactual_demand_cost"] = counterfactual_demand_cost 
    
    bill["counterfactual_cost"] = counterfactual_energy_cost + counterfactual_demand_cost +
                                  street_light(energy_dict["consumer_energy"], consumer.tariff.street_light) + 
                                  VAT(energy_dict["consumer_energy"], counterfactual_energy_cost+counterfactual_demand_cost) +
                                  firefighters(energy_dict["consumer_energy"], counterfactual_energy_cost+counterfactual_demand_cost)                   

    bill["savings"] = bill["counterfactual_cost"] - bill["total_cost"]                    
                    
    if print_output
            println(round(bill["grid_cost"], digits=2), " ",
                    round(bill["withdrawn_energy_cost"], digits =2), " ",
                    round(bill["demand_cost"], digits = 2), " ",
                    round(bill["total_cost"], digits = 2), " ",
                    " | ",
                    round(bill["counterfactual_energy_cost"], digits=2)," ",
                    round(bill["counterfactual_demand_cost"], digits=2)," ",
                    round(bill["counterfactual_cost"], digits=2)," ",
                     " | ",
                    round( bill["savings"], digits=2),)
    end

    return bill

end


function monthly_bill(energy_dict::Dict, consumer::TMT; print_output = false)

    bill = Dict{String,Any}()

    grid_energy_cost_peak = energy_dict["grid_energy_peak"]*consumer.tariff.e_cost[1][2]
    grid_energy_cost_valley = energy_dict["grid_energy_valley"]*consumer.tariff.e_cost[2][2]
    grid_energy_cost_night = energy_dict["grid_energy_night"]*consumer.tariff.e_cost[3][2]
                    
    counterfactual_energy_cost_peak = energy_dict["consumer_energy_peak"]*consumer.tariff.e_cost[1][2]
    counterfactual_energy_cost_valley = energy_dict["consumer_energy_valley"]*consumer.tariff.e_cost[2][2]
    counterfactual_energy_cost_night = energy_dict["consumer_energy_night"]*consumer.tariff.e_cost[3][2]  
                    
    grid_demand_cost_peak = energy_dict["peak_demand_peak"]*consumer.tariff.p_cost[1][2]
    grid_demand_cost_valley = energy_dict["peak_demand_valley"]*consumer.tariff.p_cost[2][2]
    grid_demand_cost_night = energy_dict["peak_demand_night"]*consumer.tariff.p_cost[3][2]
                    
    counterfactual_demand_cost_peak = energy_dict["peak_power_peak"]*consumer.tariff.p_cost[1][2]
    counterfactual_demand_cost_valley = energy_dict["peak_power_valley"]*consumer.tariff.p_cost[2][2]
    counterfactual_demand_cost_night = energy_dict["peak_power_night"]*consumer.tariff.p_cost[3][2]      

    bill["Balance"] = energy_dict;
    #Energy Costs
    bill["grid_energy_cost_peak"] = grid_energy_cost_peak
    bill["grid_energy_cost_valley"] = grid_energy_cost_valley
    bill["grid_energy_cost_night"] = grid_energy_cost_night                
    bill["withdrawn_energy_cost"] = energy_dict["withdrawn_energy"]*consumer.tariff.access
    #Demand Costs                
    bill["grid_demand_cost_peak"] = grid_demand_cost_peak
    bill["grid_demand_cost_valley"] = grid_demand_cost_valley
    bill["grid_demand_cost_night"] = grid_demand_cost_night                                

    grid_taxable_cost = grid_energy_cost_peak + grid_energy_cost_valley + grid_energy_cost_night + grid_demand_cost_peak + grid_demand_cost_valley + grid_demand_cost_night 
                    
    total_grid_energy=energy_dict["grid_energy_peak"]+energy_dict["grid_energy_valley"]+energy_dict["grid_energy_night"]+energy_dict["withdrawn_energy"]
                    
    bill["total_cost"] = grid_taxable_cost + 
                                  street_light(total_grid_energy + energy_dict["withdrawn_energy"],  consumer.tariff.street_light) + 
                                  VAT(total_grid_energy + energy_dict["withdrawn_energy"], grid_taxable_cost) +
                                  firefighters(total_grid_energy + energy_dict["withdrawn_energy"], grid_taxable_cost + bill["withdrawn_energy_cost"])                   
                    
    bill["counterfactual_energy_cost_peak"] = counterfactual_energy_cost_peak
    bill["counterfactual_energy_cost_valley"] = counterfactual_energy_cost_valley
    bill["counterfactual_energy_cost_night"] = counterfactual_energy_cost_night
                    
    bill["counterfactual_demand_cost_peak"] = counterfactual_demand_cost_peak
    bill["counterfactual_demand_cost_valley"] = counterfactual_demand_cost_valley
    bill["counterfactual_demand_cost_night"] = counterfactual_demand_cost_night  
                    
    counterfactual_grid_taxable_cost = counterfactual_energy_cost_peak + counterfactual_energy_cost_valley + counterfactual_energy_cost_night + counterfactual_demand_cost_peak + counterfactual_demand_cost_valley + counterfactual_demand_cost_night
    counterfactual_total_grid_energy=energy_dict["consumer_energy_peak"]+energy_dict["consumer_energy_valley"]+energy_dict["consumer_energy_night"]             
    
    bill["counterfactual_cost"] = counterfactual_grid_taxable_cost + 
                                  street_light(counterfactual_total_grid_energy,  consumer.tariff.street_light) + 
                                  VAT(counterfactual_total_grid_energy,  counterfactual_grid_taxable_cost) +
                                  firefighters(counterfactual_total_grid_energy,  counterfactual_grid_taxable_cost)                       
                    
    bill["savings_energy_cost_peak"] = counterfactual_energy_cost_peak - grid_energy_cost_peak
    bill["savings_energy_cost_valley"] = counterfactual_energy_cost_valley - grid_energy_cost_valley
    bill["savings_energy_cost_night"] = counterfactual_energy_cost_night - grid_energy_cost_night
    bill["savings_demand_cost_peak"] =  counterfactual_demand_cost_peak - grid_demand_cost_peak
    bill["savings_demand_cost_valley"] = counterfactual_demand_cost_valley - grid_demand_cost_valley
    bill["savings_demand_cost_night"] = counterfactual_demand_cost_night - grid_demand_cost_night     
    bill["savings"] = bill["counterfactual_cost"] -   bill["total_cost"]          

    if print_output
            println(round(bill["grid_energy_cost_peak"], digits=2), " ",    
                    round(bill["grid_energy_cost_valley"], digits=2), " ",
                    round(bill["grid_energy_cost_night"], digits=2), " ", 
                    " | ",
                    round(bill["withdrawn_energy_cost"], digits=2), " ",       
                    " | ",
                    round(bill["counterfactual_energy_cost_peak"], digits=2)," ",
                    round(bill["counterfactual_energy_cost_valley"], digits=2)," ",
                    round(bill["counterfactual_energy_cost_night"],  digits=2)," ",        
                     " | ",
                    round(bill["grid_demand_cost_peak"], digits=2), " ",    
                    round(bill["grid_demand_cost_valley"], digits=2), " ",
                    round(bill["grid_demand_cost_night"], digits=2), " ", 
                    " | ",        
                    round(bill["counterfactual_demand_cost_peak"], digits=2)," ",
                    round(bill["counterfactual_demand_cost_valley"], digits=2)," ",
                    round(bill["counterfactual_demand_cost_night"],  digits=2)," ",        
                     " | ",        
                    round(bill["savings"], digits=2)," ",)

    end             
                    
    return bill

end