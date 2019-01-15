#Residential Consumer Balancing Code
function annual_energy_balance_nmw(consumer::Residential, pvsys::PVSystem; print_output=false)
    
    results = Dict{Int64,Any}()
    
    d_d = Truncated(Normal(0.0, 0.5), -0.10, 0.10)
    d_s = Truncated(Normal(-0.2, 0.5), -0.10, 0.15)
    days_p_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m_h = 0
    count = 0

    # Initial conditions
    carry_over = 0.0
    global_allowance = 0.0
    global_withdrawl = 0.0
    global_generation = 0.0
    energy_loss = 0.0

    #Loop for every Month of the year 
    for (ix,m) in enumerate(days_p_month)
        
        #Get solar Data with houtly resolution for the month 
        solar_month_base = pvsys.time_series[24*(m_h) + 1:24*(m_h+m)]
        solar_month = [(s+rand(d_s, 1)[1])*(s > 0.1) for s in solar_month_base]*pvsys.capacity
        m_h = m

        #Simulate month on an hourly basis 
        #initial conditions. 
        grid_energy = 0.0 
        withdrawn_energy = 0.0
        consumer_energy = 0.0
        PV_energy = 0.0
        inyection_grid = 0.0

        #Loop for every day of the month 
        for i in 1:m
            var = rand(d_d, 24).+1.0
            daily_p = (consumer.load_curve.*var)*consumer.peak_power[ix]
            solar_day = solar_month[(((m-1)*24)+1):(((m-1)*24)+24)]

            #Loop for every hour of the day  
            for t in 1:24

               consumer_energy += daily_p[t]

               PV_energy +=  solar_day[t] 

               balance = daily_p[t] - solar_day[t]

               inyection_grid += max(0.0, -1*balance) 

               grid_energy += max(0.0,balance) 

            end #end of hourly loop 

        end #end of month loop

           global_generation += PV_energy #GenAcum
           global_allowance = 0.49*PV_energy
           global_withdrawl += min(global_allowance,inyection_grid)
           energy_loss = max(0.0, inyection_grid - global_allowance)     
           carry_over = 0.0  
                
           results[ix] = Dict("consumer_energy" => consumer_energy,
                               "PV_energy" => PV_energy,
                                "inyection_grid" => inyection_grid,
                                "withdrawn_energy" => min(global_allowance,inyection_grid),
                            "grid_energy" => grid_energy,
                            "carry_over" => carry_over,
                            "global_generation" => global_generation,
                            "global_withdrawl" => global_withdrawl,
                            "global_allowance" => global_allowance,
                            "energy_loss" => energy_loss
                    )     
    end
    
    if print_output 
        print_residential(results)
    end
            
    return results        
            
end   

        
#Commercial and Industrial Consumer Balancing Code        
function annual_energy_balance_nmw(consumer::CommIndus, pvsys::PVSystem; print_output=false)

    results = Dict{Int64,Any}()
    
    d_d = Truncated(Normal(0.0, 0.5), -0.10, 0.10)
    d_s = Truncated(Normal(-0.2, 0.5), -0.10, 0.15)
    days_p_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m_h = 0
    count = 0

    # Initial conditions
    peak_power = 0.0
    peak_demand = 0.0
    carry_over = 0.0
    global_allowance = 0.0
    global_withdrawl = 0.0
    global_generation = 0.0
    energy_loss = 0.0

    #Loop for every Month of the year 
    for (ix,m) in enumerate(days_p_month)
        
        #Get solar Data with houtly resolution for the month 
        solar_month_base = pvsys.time_series[24*(m_h) + 1:24*(m_h+m)]
        solar_month = [(s+rand(d_s, 1)[1])*(s > 0.1) for s in solar_month_base]*pvsys.capacity
        m_h = m

        #Simulate month on an hourly basis 
        #initial conditions. 
        grid_energy = 0.0 
        withdrawn_energy = 0.0
        consumer_energy = 0.0
        PV_energy = 0.0
        inyection_grid = 0.0

        #Loop for every day of the month 
        for i in 1:m
            var = rand(d_d, 24).+1.0
            daily_p = (consumer.load_curve.*var)*consumer.peak_power[ix]
            solar_day = solar_month[(((m-1)*24)+1):(((m-1)*24)+24)]

                #Loop for every hour of the day  
                for t in 1:24

                   consumer_energy += daily_p[t]

                   PV_energy +=  solar_day[t] 

                   balance = daily_p[t] - solar_day[t]
            
                   peak_power = max(peak_power, daily_p[t]) 
               
                   peak_demand = max(peak_demand, balance)   

                   inyection_grid += max(0.0, -1*balance) 

                   grid_energy += max(0.0,balance) 

                end #end of hourly loop 

            end #end of month loop

           global_generation += PV_energy #GenAcum
           global_allowance = 0.49*PV_energy
           global_withdrawl += min(global_allowance,inyection_grid)
           energy_loss = max(0.0, inyection_grid - global_allowance)     
           carry_over = 0.0  
                
           results[ix] = Dict("consumer_energy" => consumer_energy,
                               "PV_energy" => PV_energy,
                                "inyection_grid" => inyection_grid,
                                "withdrawn_energy" => min(global_allowance,inyection_grid),
                            "grid_energy" => grid_energy,
                            "peak_demand" => peak_demand,
                            "peak_power" => peak_power,
                            "carry_over" => carry_over,
                            "global_generation" => global_generation,
                            "global_withdrawl" => global_withdrawl,
                            "global_allowance" => global_allowance,
                            "energy_loss" => energy_loss
                    )
            
        peak_power = 0.0
        peak_demand = 0.0             
            
    end
    
    if print_output 
        print_commercial(results)
    end
                    
    return results        
            
end   
                
                
#TMT Consumer Balancing Code        
function annual_energy_balance_nmw(consumer::TMT, pvsys::PVSystem; print_output=false)     
                    
    results = Dict{Int64,Any}()
    
    d_d = Truncated(Normal(0.0, 0.5), -0.10, 0.10)
    d_s = Truncated(Normal(-0.2, 0.5), -0.10, 0.15)
    days_p_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m_h = 0
    count = 0
                   
    carry_over = 0.0
    global_allowance = 0.0
    global_withdrawl = 0.0
    global_generation = 0.0
    energy_loss = 0.0

    #Loop for every Month of the year 
    for (ix,m) in enumerate(days_p_month)
        
        # Initial monthly conditions
        peak = [10, 11, 12, 17, 18, 19]
        peak_power_peak = 0.0
        peak_demand_peak = 0.0      

        valley = [6, 7, 8, 9, 13, 14, 15, 16]
        peak_power_valley = 0.0
        peak_demand_valley = 0.0

        night = [20, 21, 22, 23, 24, 1, 2, 3, 4, 5]                
        peak_power_night = 0.0                
        peak_demand_night = 0.0
                        
        #Get solar Data with houtly resolution for the month 
        solar_month_base = pvsys.time_series[24*(m_h) + 1:24*(m_h+m)]
        solar_month = [(s+rand(d_s, 1)[1])*(s > 0.1) for s in solar_month_base]*pvsys.capacity
        m_h = m

        #Simulate month on an hourly basis 
        #initial conditions. 
        withdrawn_energy = 0.0
        consumer_energy_peak = 0.0
        consumer_energy_valley = 0.0
        consumer_energy_night = 0.0
        grid_energy_peak = 0.0
        grid_energy_valley = 0.0
        grid_energy_night = 0.0                
        PV_energy = 0.0
        inyection_grid = 0.0

        #Loop for every day of the month 
        for i in 1:m
            var = rand(d_d, 24).+1.0
            daily_p = (consumer.load_curve.*var)*consumer.peak_power[ix]
            solar_day = solar_month[(((m-1)*24)+1):(((m-1)*24)+24)]

            #Loop for every hour of the day  
            for t in 1:24
                
                                
               (t in peak) ? consumer_energy_peak += daily_p[t] : true
               (t in valley) ? consumer_energy_valley += daily_p[t] : true                  
               (t in night) ? consumer_energy_night += daily_p[t] : true 

               PV_energy +=  solar_day[t] 
               
               #println(t,"--------")  
               #println("PV"," ", solar_day[t]) 
               #println("---------")                   
               balance = daily_p[t] - solar_day[t]

               inyection_grid += max(0.0, -1*balance) 
               
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
               
                                            
               available_energy = carry_over + max(0.0, -1*balance)  

               withdrawl = 0.0 

               if balance >= 0.0

                    withdrawl = available_energy - balance

                    if withdrawl > 0.0 #There is enough stored to meet energy demand in t 

                        #Book Keeping

                        withdrawn_energy += balance

                        (t in peak) ? grid_energy_peak += 0.0 : true
                        (t in valley) ? grid_energy_valley += 0.0 : true                  
                        (t in night) ? grid_energy_night += 0.0 : true                 

                        carry_over = withdrawl

                    elseif withdrawl <= 0.0 #There is not enough stored to meet energy demand in t                        

                        withdrawn_energy += available_energy

                        carry_over = 0.0    
                                            
                        (t in peak) ? grid_energy_peak -= withdrawl : true
                        (t in valley) ? grid_energy_valley -= withdrawl : true                  
                        (t in night) ? grid_energy_night -= withdrawl : true                      

                    end

               elseif balance < 0.0

                    carry_over  = available_energy     

               end

            end #end of hourly loop 

        end #end of month loop
                                
           global_generation += PV_energy #GenAcum
           global_allowance = 0.49*PV_energy
           global_withdrawl += min(global_allowance,inyection_grid)
           energy_loss = max(0.0, inyection_grid - global_allowance)     
           carry_over = 0.0  
                
                
           results[ix] = Dict("consumer_energy_peak" => consumer_energy_peak,
                              "consumer_energy_valley" => consumer_energy_valley,
                              "consumer_energy_night" => consumer_energy_night,
                              "PV_energy" => PV_energy,
                              "inyection_grid" => inyection_grid,
                              "withdrawn_energy" => withdrawn_energy,
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
                              "global_withdrawl" => global_withdrawl,
                              "global_allowance" => global_allowance,
                        )     

    end
    
    if print_output 
        print_TMT(results)
    end
    
    return results        
            
end                   