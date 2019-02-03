function print_residential(energy_totals::Dict)

                println("month", " ", "consumer_energy", " ", 
                                "PV_energy", " ", 
                                " | ",
                                "injection_grid", " ",  
                                "withdrawn_energy", " ", 
                                "grid_energy", " ",
                                " | ",
                                "global_generation"," ", 
                                "global_withdrawal", " ",
                                "global_allowance", " ", 
                                "max_surplus", " ",
                                "carryover"," ") 
        
        
        for i in 1:12
    
                println(i, " ",round(energy_totals[i]["consumer_energy"], digits=2), " ", 
                                round(energy_totals[i]["PV_energy"], digits =2), " ", 
                                " | ",
                                round(energy_totals[i]["injection_grid"], digits = 2), " ",  
                                round(energy_totals[i]["withdrawn_energy"],digits=2), " ", 
                                round(energy_totals[i]["grid_energy"], digits=2), " ",
                                " | ",
                                round(energy_totals[i]["global_generation"], digits=2)," ", 
                                round(energy_totals[i]["global_withdrawal"], digits=2), " ",
                                round(energy_totals[i]["global_allowance"], digits=2), " ", 
                                round(energy_totals[i]["max_surplus"], digits=2), " ",
                                round(energy_totals[i]["carry_over"],digits=2), " ") 
        
     end

end

function print_commercial(energy_totals::Dict)
    
                println("month", " ", "consumer_energy", " ", 
                                "PV_energy", " ", 
                                " | ",
                                "injection_grid", " ",  
                                "withdrawn_energy", " ", 
                                "grid_energy", " ",
                                " | ",
                                "peak_power", " ",
                                "peak_demand", " ",
                                " | ",
                                "global_generation"," ", 
                                "global_withdrawal", " ",
                                "global_allowance", " ", 
                                "max_surplus", " ",
                                "carry_over", " ")
        


           for i in 1:12
                println(i, " ", round(energy_totals[i]["consumer_energy"], digits=2), " ", 
                                round(energy_totals[i]["PV_energy"], digits =2), " ", 
                                " | ",
                                round(energy_totals[i]["injection_grid"], digits = 2), " ",  
                                round(energy_totals[i]["withdrawn_energy"],digits=2), " ", 
                                round(energy_totals[i]["grid_energy"], digits=2), " ",                                
                                " | ",
                                round(energy_totals[i]["peak_power"], digits=2), " ",
                                round(energy_totals[i]["peak_demand"], digits=2), " ",
                                " | ",
                                round(energy_totals[i]["global_generation"], digits=2)," ", 
                                round(energy_totals[i]["global_withdrawal"], digits=2), " ",
                                round(energy_totals[i]["global_allowance"], digits=2), " ", 
                                round(energy_totals[i]["max_surplus"], digits=2), " ",
                                round(energy_totals[i]["carry_over"],digits=2), " ")
        end

end

function print_TMT(energy_totals::Dict)

                println("month", " | ","consumer_energy_peak", " ",
                                "consumer_energy_valley", " ",
                                "consumer_energy_night", " ",
                                " | ",
                                "PV_energy", " ", 
                                "injection_grid", " ",  
                                "withdrawn_energy", " ", 
                                " | ",        
                                "grid_energy_peak", " ",
                                "grid_energy_valley", " ",
                                "grid_energy_night", " ",        
                                " | ",                     
                                "peak_power_peak", " ",
                                "peak_power_valley", " ",
                                "peak_power_night", " ", 
                                " | ",        
                                "peak_demand_peak", " ",
                                "peak_demand_valley", " ",
                                "peak_demand_night", " ",        
                                " | ",
                                "global_generation"," ", 
                                "global_withdrawal", " ",
                                "global_allowance", " ", 
                                "max_surplus", " ",
                                "carry_over") 
    
     for i in 1:12 
                println(i," | ",round(energy_totals[i]["consumer_energy_peak"], digits=2), " ",
                                round(energy_totals[i]["consumer_energy_valley"], digits=2), " ",
                                round(energy_totals[i]["consumer_energy_night"], digits=2), " ",
                                " | ",
                                round(energy_totals[i]["PV_energy"], digits =2), " ", 
                                round(energy_totals[i]["injection_grid"], digits = 2), " ",  
                                round(energy_totals[i]["withdrawn_energy"],digits=2), " ", 
                                " | ",
                                round(energy_totals[i]["grid_energy_peak"], digits=2), " ",
                                round(energy_totals[i]["grid_energy_valley"], digits=2), " ",
                                round(energy_totals[i]["grid_energy_night"], digits=2), " ",                            
                                " | ",
                                round(energy_totals[i]["peak_power_peak"], digits=2), " ",
                                round(energy_totals[i]["peak_power_valley"], digits=2), " ",
                                round(energy_totals[i]["peak_power_night"], digits=2), " ", 
                                " | ",      
                                round(energy_totals[i]["peak_demand_peak"], digits=2), " ",
                                round(energy_totals[i]["peak_demand_valley"], digits=2), " ",
                                round(energy_totals[i]["peak_demand_night"], digits=2), " ",        
                                " | ",
                                round(energy_totals[i]["global_generation"], digits=2)," ", 
                                round(energy_totals[i]["global_withdrawal"], digits=2), " ",
                                round(energy_totals[i]["global_allowance"], digits=2), " ", 
                                round(energy_totals[i]["max_surplus"], digits=2), " ",
                                round(energy_totals[i]["carry_over"], digits=2), " ") 
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