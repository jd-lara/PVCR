function make_power_curve(consumer::Consumer, days::Int64)
    
    d_d = Truncated(Normal(0.0, 0.5), -0.10, 0.10)
    demand_curve = Array{Float64,1}()
    for days in 1:days
        var = rand(d_d, 24).+1.0
        daily_p = (consumer.load_curve.*var)*consumer.peak_power[3]
        demand_curve = vcat(demand_curve, daily_p)
    end

    return demand_curve
end    

function make_pv_curve(pvsys::PVSystem, days::Int64)

    d_s = Truncated(Normal(-0.2, 0.5), -0.10, 0.15)
    pv_curve = Array{Float64,1}()
    for days in 1:days
        solar_day_base = pvsys.time_series[(15+days)*24:(((16+days)*24) -1)]
        solar_day = [(s+rand(d_s, 1)[1])*(s > 0.1) for s in solar_day_base]*pvsys.capacity
        pv_curve = vcat(pv_curve,solar_day)
    end
    
    return pv_curve
end


function simulate(consumer::Consumer, pvsys::PVSystem, days::Int64)
    
    demand_curve = make_power_curve(consumer, days)
    pv_curve = make_pv_curve(pvsys, days)
    
    time_series = Dict{String,Array{Float64}}()

    available_energy_h = Array{Float64,1}()
    grid_energy_h = Array{Float64,1}()
    withdrawn_energy_h = Array{Float64,1}()
    withdrawal_h = Array{Float64,1}()
    consumer_energy_h = Array{Float64,1}()
    PV_energy_h = Array{Float64,1}()
    injection_grid_h = Array{Float64,1}()
    stored_energy_h = Array{Float64,1}()
    carry_over_h = Array{Float64,1}()
    
    #memory
    available_energy = 0.0
    grid_energy = 0.0 
    withdrawn_energy = 0.0
    consumer_energy = 0.0
    PV_energy = 0.0
    injection_grid = 0.0
    carry_over = 0.0

    for day in 1:days 
        daily_p = demand_curve[1+(day-1)*24:24+(day-1)*24]
        solar_day = pv_curve[1+(day-1)*24:24+(day-1)*24]

        #Loop for every hour of the day  
        for t in 1:24

           consumer_energy += daily_p[t]
           push!(consumer_energy_h,consumer_energy)

           PV_energy +=  solar_day[t] 
           push!(PV_energy_h,PV_energy)

           balance = daily_p[t] - solar_day[t]
           push!(injection_grid_h, balance) 

           injection_grid += max(0.0, -1*balance) 
           push!(stored_energy_h, injection_grid)

           available_energy =  carry_over + max(0.0, -1*balance)  
           push!(available_energy_h, available_energy) 

           withdrawal = 0.0 

           if balance >= 0.0

                withdrawal = available_energy - balance


                if withdrawal > 0.0 #There is enough stored to meet energy demand in t 

                    #Book Keeping

                    withdrawn_energy += balance
                    push!(withdrawal_h, balance)
                    push!(withdrawn_energy_h, withdrawn_energy)

                    grid_energy += 0.0
                    push!(grid_energy_h,grid_energy)

                    carry_over = withdrawal
                    push!(carry_over_h, withdrawal)

                elseif withdrawal <= 0.0 #There is not enough stored to meet energy demand in t                        

                    withdrawn_energy += available_energy
                    push!(withdrawal_h, available_energy)
                    push!(withdrawn_energy_h, withdrawn_energy)

                    carry_over = 0.0
                    push!(carry_over_h,0.0)

                    grid_energy -= withdrawal
                    push!(grid_energy_h,grid_energy)

                end

           elseif balance < 0.0

                carry_over = available_energy 
                push!(carry_over_h,carry_over)
                push!(grid_energy_h,grid_energy)
                push!(withdrawal_h, 0.0)
                push!(withdrawn_energy_h, withdrawn_energy)

           end

        end #end of hourly loop 


    end    

    time_series["available_energy_h"] = available_energy_h
    time_series["grid_energy_h"] = grid_energy_h 
    time_series["withdrawn_energy_h"] = withdrawn_energy_h
    time_series["withdrawal_h"] = withdrawal_h
    time_series["consumer_energy_h"] = consumer_energy_h
    time_series["PV_energy_h"] = PV_energy_h
    time_series["injection_grid_h"] = injection_grid_h
    time_series["stored_energy_h"] = stored_energy_h
    time_series["carry_over_h"] = carry_over_h
    time_series["demand_curve"] = demand_curve
    time_series["pv_curve"] = pv_curve
        
    return time_series    
        
end
        
#=
plot(consumer_energy_h)
plot!(PV_energy_h+grid_energy_h-stored_energy_h+withdrawn_energy_h, fill=(0, :blue))
plot!(PV_energy_h+grid_energy_h-stored_energy_h, fill=(0, :red))
plot!(grid_energy_h, fill=(0, :green))
=#