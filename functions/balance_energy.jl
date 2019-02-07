#Residential Consumer Balancing Code
function annual_energy_balance(consumer::C, pvsys::PVSystem; print_output=false) where {C <: Consumer}
    
    results = Dict{Int64,Any}()
    
    d_d = Truncated(Normal(0.0, 0.5), -0.10, 0.10)
    d_s = Truncated(Normal(-0.2, 0.5), -0.10, 0.15)
    days_p_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m_h = 0
    count = 0

    # Initial conditions
    carry_over = 0.0
    global_allowance = 0.0
    global_withdrawal = 0.0
    global_generation = 0.0

  #Loop for every Month of the year 
    for (ix,m) in enumerate(days_p_month)
        
        #Get solar Data with houtly resolution for the month 
        solar_month_base = pvsys.time_series[24*(m_h) + 1:24*(m_h+m)]
        solar_month = [(s+rand(d_s, 1)[1])*(s > 0.1) for s in solar_month_base]*pvsys.capacity
        m_h = m

        #Simulate month on an hourly basis 
        #initial conditions for the month
        allowance = 0.0
        utility_supplied_energy = 0.0
        grid_energy = 0.0
        withdrawn_energy = 0.0
        consumer_energy = 0.0
        PV_energy = 0.0
        injection_grid = 0.0
        peak_power = 0.0
        peak_demand = 0.0
        
        # Initial monthly conditions
        peak = [10, 11, 12, 17, 18, 19]
        valley = [6, 7, 8, 9, 13, 14, 15, 16]
        night = [20, 21, 22, 23, 24, 1, 2, 3, 4, 5]                
    
        consumer_energy_peak = 0.0
        consumer_energy_valley = 0.0
        consumer_energy_night = 0.0
        
        grid_energy_peak = 0.0
        grid_energy_valley = 0.0
        grid_energy_night = 0.0 

        #Loop for every day of the month 
        for i in 1:m
            var = rand(d_d, 24).+1.0
            daily_p = (consumer.load_curve.*var)*consumer.peak_power[ix]
            solar_day = solar_month[(((m-1)*24)+1):(((m-1)*24)+24)]

            #Loop for every hour of the day  
            for t in 1:24

               consumer_energy += daily_p[t]
            
               (t in peak) ?   consumer_energy_peak += daily_p[t] : true
               (t in valley) ? consumer_energy_valley += daily_p[t] : true                  
               (t in night) ?  consumer_energy_night += daily_p[t] : true  

               PV_energy +=  solar_day[t] 

               balance = daily_p[t] - solar_day[t]
               
               (t in peak) ? grid_energy_peak += max(0.0,balance) : true
               (t in valley) ? grid_energy_valley += max(0.0,balance) : true                  
               (t in night) ? grid_energy_night += max(0.0,balance) : true 
                
               grid_energy = grid_energy_peak + grid_energy_valley + grid_energy_night  
                
               injection_grid += max(0.0, -1*balance) 
            
               peak_power = max(peak_power, daily_p[t]) 
               
               peak_demand = max(peak_demand, balance)                    

            end #end of hourly loop 
        
        
        
        end #end of daily loop
    
            global_generation += PV_energy #Total Energy from Rooftop PV
            global_allowance = 0.49*global_generation - global_withdrawal # Uses the acumulated withdrawls up to month ix-1
            allowance = min(injection_grid+carry_over, global_allowance)
            withdrawn_energy = min(min(grid_energy,injection_grid+carry_over),allowance) #Withdrawn Energy From the Grid
            utility_supplied_energy = max(grid_energy - injection_grid - carry_over,0.0)
             
            #Update quantities for next month
            carry_over = max(allowance - withdrawn_energy, 0) 
            global_withdrawal += withdrawn_energy #Total Energy withdrawn resulting from injections into the grid
            
          utility = Dict("consumer_energy_peak" => consumer_energy_peak,   
                    "consumer_energy_valley" => consumer_energy_valley,
                    "consumer_energy_night" => consumer_energy_night,
                    "grid_energy_peak" => grid_energy_peak,   
                    "grid_energy_valley" => grid_energy_valley,
                    "grid_energy_night" =>  grid_energy_night
               )
        
           results[ix] = Dict("consumer_energy" => consumer_energy,
                   "PV_energy" => PV_energy,
                    "injection_grid" => injection_grid,
                    "withdrawn_energy" => withdrawn_energy,
                    "utility_supplied_energy" => utility_supplied_energy,
                "grid_energy" => grid_energy,
                "peak_demand" => peak_demand,
                "peak_power" => peak_power,
                "carry_over" => carry_over,
                "allowance" => allowance,
                "global_generation" => global_generation,
                "global_withdrawal" => global_withdrawal,
                "global_allowance" => global_allowance,
                "utility_balance" => utility)
        

    
    end #end of monthly loop
    
    if print_output 
        print_base(results)
    end
            
    return results        
            
end          
                

#TMT Consumer Balancing Code        
function annual_energy_balance(consumer::TMT, pvsys::PVSystem; print_output=false)     
   results = Dict{Int64,Any}()
    
    d_d = Truncated(Normal(0.0, 0.5), -0.10, 0.10)
    d_s = Truncated(Normal(-0.2, 0.5), -0.10, 0.15)
    days_p_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m_h = 0
    count = 0
                   
    # Initial conditions
    carry_over = 0.0
    global_allowance = 0.0
    global_withdrawal = 0.0
    global_generation = 0.0

    #Loop for every Month of the year 
    for (ix,m) in enumerate(days_p_month)
        
        #Simulate month on an hourly basis 
        #initial conditions for the month
        allowance = 0.0
        utility_supplied_energy = 0.0
        grid_energy = 0.0
        withdrawn_energy = 0.0
        consumer_energy = 0.0
        PV_energy = 0.0
		
		peak_power_peak = 0.0
        peak_demand_peak = 0.0      
        
		peak_power_valley = 0.0
        peak_demand_valley = 0.0            
        
		peak_power_night = 0.0                
        peak_demand_night = 0.0
        
		consumer_energy_peak = 0.0
        consumer_energy_valley = 0.0
        consumer_energy_night = 0.0
        
		grid_energy_peak = 0.0
        grid_energy_valley = 0.0
        grid_energy_night = 0.0
		
        total_injection = 0.0
		injection_grid_peak = 0.0
		injection_grid_valley = 0.0
		injection_grid_night = 0.0
		
        # Initial monthly conditions
        peak = [10, 11, 12, 17, 18, 19]
        valley = [6, 7, 8, 9, 13, 14, 15, 16]
        night = [20, 21, 22, 23, 24, 1, 2, 3, 4, 5]  
		   
        #Get solar Data with houtly resolution for the month 
        solar_month_base = pvsys.time_series[24*(m_h) + 1:24*(m_h+m)]
        solar_month = [(s+rand(d_s, 1)[1])*(s > 0.1) for s in solar_month_base]*pvsys.capacity
        m_h = m
		
        #Loop for every day of the month 
        for i in 1:m
            var = rand(d_d, 24).+1.0
            daily_p = (consumer.load_curve.*var)*consumer.peak_power[ix]
            solar_day = solar_month[(((m-1)*24)+1):(((m-1)*24)+24)]

            #Loop for every hour of the day  
            for t in 1:24
                
			   consumer_energy += daily_p[t]
            
               (t in peak) ?   consumer_energy_peak += daily_p[t] : true
               (t in valley) ? consumer_energy_valley += daily_p[t] : true                  
               (t in night) ?  consumer_energy_night += daily_p[t] : true  

               PV_energy +=  solar_day[t] 

               balance = daily_p[t] - solar_day[t]
               
               (t in peak) ? grid_energy_peak += max(0.0,balance) : true
               (t in valley) ? grid_energy_valley += max(0.0,balance) : true                  
               (t in night) ? grid_energy_night += max(0.0,balance) : true 
                
               grid_energy = grid_energy_peak + grid_energy_valley + grid_energy_night  
                
               (t in peak) ?  injection_grid_peak += max(0.0, -1*balance) : true
			   (t in valley) ? injection_grid_valley += max(0.0, -1*balance) : true
			   (t in night) ? injection_grid_night += max(0.0, -1*balance) : true 
				
			   total_injection = injection_grid_peak + injection_grid_valley + injection_grid_night
               
               #Peak demand corresponds to the peak as measured by the distribution company 
                                
               #(t in peak) ? println("peak d"," ",  peak_demand_peak, " ", balance, " ", max(0.0, peak_demand_peak, max(0.0,balance)) ) : true
               (t in peak) ? peak_demand_peak = max(0.0, peak_demand_peak, max(0.0,balance)) : true
                 
               #(t in valley) ? println("valley d", " ", peak_demand_valley," ",  balance, " ", max(0.0, peak_demand_valley, max(0.0,balance)) ) : true      
               (t in valley) ? peak_demand_valley = max(0.0, peak_demand_valley, max(0.0,balance)) : true    
                               
               #(t in night) ? println("night d", " ", peak_demand_night, " ", balance, " ", max(0.0, peak_demand_night, max(0.0,balance)) ) : true 
               (t in night) ? peak_demand_night = max(0.0, peak_demand_night, max(0.0,balance)) : true                  
                
               #Peak power corresponds to the peak of the consumer load
                                
               #(t in peak) ? println("peak p", " ", peak_power_peak, " ", daily_p[t], " ", max(0.0, peak_power_peak, daily_p[t]) ) : true                    
               (t in peak) ? peak_power_peak = max(0.0, peak_power_peak, daily_p[t]) : true
                      
               #(t in valley) ? println("valley p", " ", peak_power_valley, " ", daily_p[t], " ", max(0.0, peak_power_valley, daily_p[t])) : true          
               (t in valley) ? peak_power_valley = max(0.0, peak_power_valley, daily_p[t]) : true  
               
               #(t in night) ? println("night p", " ", peak_power_night, " ", daily_p[t], " ", max(0.0, peak_power_night, daily_p[t]) ) : true                 
               (t in night) ? peak_power_night = max(0.0, peak_power_night, daily_p[t]) : true  
               
                                            
            end #end of hourly loop 

		end #end of daily loop
                
            global_generation += PV_energy #Total Energy from Rooftop PV
            global_allowance = 0.49*global_generation - global_withdrawal # Uses the acumulated withdrawls up to month ix-1
            allowance = min(total_injection+carry_over, global_allowance)

			if !(carry_over > 0.0)  
			
				withdrawn_energy = min(min(grid_energy,total_injection),allowance) #Withdrawn Energy From the Grid
				utility_supplied_energy_peak = max(grid_energy_peak - injection_grid_peak,0.0)
				utility_supplied_energy_valley = max(grid_energy_valley- injection_grid_valley,0.0)
				utility_supplied_energy_night = max(grid_energy_night,0.0)
                #Update quantities for next month
				carry_over = max(allowance - withdrawn_energy, 0) 
			elseif carry_over > 0.0
                temp_carry_over = 0.0
            
				withdrawn_energy = min(min(grid_energy,total_injection +carry_over),allowance) #Withdrawn Energy From the Grid
            
				grid_energy_valley - injection_grid_valley > 0 ? temp_carry_over = min(carry_over, grid_energy_valley - injection_grid_valley) : temp_carry_over = 0.0
				utility_supplied_energy_valley = max((grid_energy_valley - injection_grid_valley - temp_carry_over), 0.0)
				
				grid_energy_peak - injection_grid_peak > 0 ? temp_carry_over = min(carry_over - temp_carry_over, grid_energy_valley - injection_grid_valley) : temp_carry_over = 0.0
                utility_supplied_energy_peak = max((grid_energy_peak - injection_grid_peak - temp_carry_over), 0.0)
				
				temp_carry_over = min(carry_over - temp_carry_over, grid_energy_night)
				utility_supplied_energy_night = max(grid_energy_night - temp_carry_over,0.0)	
				
				carry_over = max(allowance - withdrawn_energy, 0)
		   end
		            
            
            global_withdrawal += withdrawn_energy #Total Energy withdrawn resulting from injections into the grid
            
          utility = Dict("consumer_energy_peak" => consumer_energy_peak,   
                    "consumer_energy_valley" => consumer_energy_valley,
                    "consumer_energy_night" => consumer_energy_night,
                    "grid_energy_peak" => grid_energy_peak,   
                    "grid_energy_valley" => grid_energy_valley,
                    "grid_energy_night" =>  grid_energy_night
               )
        	
           results[ix] = Dict("consumer_energy_peak" => consumer_energy_peak,
                              "consumer_energy_valley" => consumer_energy_valley,
                              "consumer_energy_night" => consumer_energy_night,
                              "PV_energy" => PV_energy,
							  "grid_energy" => grid_energy, 
                              "total_injection" => total_injection,
                              "withdrawn_energy" => withdrawn_energy,
							  "utility_supplied_energy_peak" => utility_supplied_energy_peak,
                              "utility_supplied_energy_valley" => utility_supplied_energy_valley,
                              "utility_supplied_energy_night" => utility_supplied_energy_night,
                              "grid_energy_peak" => grid_energy_peak,
                              "grid_energy_valley" => grid_energy_valley,
                              "grid_energy_night" => grid_energy_night,
                              "peak_demand_peak" => peak_demand_peak,
                              "peak_demand_valley" => peak_demand_valley,
                              "peak_demand_night" => peak_demand_night,
                              "peak_power_peak" => peak_power_peak,
                              "peak_power_valley" => peak_power_valley,
                              "peak_power_night" => peak_power_night,
                              "carry_over" => carry_over,
                              "global_generation" => global_generation,
                              "global_withdrawal" => global_withdrawal,
                              "global_allowance" => global_allowance,
                              "utility_balance" => utility,
                        )     

    end
    
    if print_output 
        print_TMT(results)
    end
    
    return results        
            
end                   
