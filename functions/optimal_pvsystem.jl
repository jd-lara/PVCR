function PV_savings(consumer_input::Consumer, system::PVSystem; tariff_increase=true)
    
    consumer = deepcopy(consumer_input)
    
    netsavings = Array{Float64,2}(undef,12,consumer.decision_timeframe)
    
    for y in 1:consumer.decision_timeframe
                
        ebalance = annual_energy_balance(consumer, system, print_output=false);
        
        for m in 1:12

            bill = monthly_bill(ebalance[m], consumer, print_output=false)

            netsavings[m,y] = bill["total_savings"]

        end
        
        tariff_increase ? increase_tariff!(consumer) : true
        
    end

    return netsavings
        
end

function PV_cashflow(consumer::T, system::PVSystem, financial_terms::Financial; tariff_increase=true) where {T <: Consumer}
    
    #println(consumer.econsumption, " ", system.capacity)
    if system.capacity > 0.0
        PV = PVCost(system,1.0)
        payment = amortize(financial_terms.apr/12, financial_terms.term*12, PV*(1-financial_terms.downpayment))
    else
        #dirty way to have 0 payments, needs some fixing later
        PV = 0.0
		payment = amortize(financial_terms.apr/12, financial_terms.term*12, 0.0)    
    end

    bill_savings = PV_savings(consumer, system; tariff_increase=tariff_increase)
      
    for y in 1:financial_terms.term
            
        for m in 1:12

            bill_savings[m,y] = bill_savings[m,y] - payment[4]*financial_terms.XhR

        end
        
    end
	
	bill_savings[1,1] -= PV*(financial_terms.downpayment)

    return bill_savings
        
end
	
function PV_cashflow(consumer::Residential, system::PVSystem, financial_terms::Financial; tariff_increase=true)
    
    #println(consumer.econsumption, " ", system.capacity)
    if system.capacity > 0.0
        PV = PVCost(system,financial_terms.XhR)
        payment = amortize(financial_terms.apr/12, financial_terms.term*12, PV*(1-financial_terms.downpayment))
    else
        #dirty way to have 0 payments, needs some fixing later
        payment = amortize(financial_terms.apr/12, financial_terms.term*12, 0.0)    
    end

    bill_savings = PV_savings(consumer, system; tariff_increase=tariff_increase)
      
    for y in 1:financial_terms.term
            
        for m in 1:12

            bill_savings[m,y] = bill_savings[m,y] - payment[4]

        end
        
    end

    return bill_savings
        
end	
    
function optimal_pv(consumer::Residential, system::PVSystem, capacity_range::StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}}, financial_terms::Financial; tariff_increase=true)
    
    results = Array{Float64,2}(undef, length(capacity_range), 2)    
        
    for (ix,cap) in enumerate(capacity_range)
            system.capacity = cap
            cash_flows = PV_cashflow(consumer, system, financial_terms, tariff_increase=tariff_increase)
            annuities = sum(cash_flows,dims=1)
            
			if sum(annuities[1:5]) < 100 
			
				results[ix,2] = -99
				results[ix,1] = 0.0;	
									
			else
						
				results[ix,2] = npv(annuities, consumer.rate_return) 
				results[ix,1] = cap;			
						
            end
				
				
    end    
				
	fm = findmax(results[:,2])		

	if fm[1] == -99
		return (0.0, 0.0), results					
	else
		return (fm[1], capacity_range[fm[2]]), results
	end
					
end
		
function optimal_pv(consumer::T, system::PVSystem, capacity_range::StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}}, financial_terms::Financial; tariff_increase=true) where {T <: Consumer}
    
    results = Array{Float64,2}(undef, length(capacity_range), 2)    
        
    for (ix,cap) in enumerate(capacity_range)
            system.capacity = cap
            cash_flows = PV_cashflow(consumer, system, financial_terms, tariff_increase=tariff_increase)
            annuities = sum(cash_flows,dims=1)
            if sum(annuities) < 100 
			
				results[ix,2] = -99
				results[ix,1] = 0.0;	
									
			else
						
				results[ix,2] = npv(annuities, consumer.rate_return) 
				results[ix,1] = cap;			
						
            end
				
				
    end    
				
	fm = findmax(results[:,2])		

	if fm[1] == -99
		return (0.0, 0.0), results					
	else
		return (fm[1], capacity_range[fm[2]]), results
	end
    
end		

function plot_monte_carlo_model_prediction(company, tariff, random_consumption, mc_data; width=50)
    fig = plt.figure()
    ax1 = fig.add_subplot()
    ax1.boxplot([[mc_data[j][i] for j in 1:size(mc_data,1)] for i in 1:size(mc_data[1],1)], positions=random_consumption, manage_ticks=false, widths=width)
#     ax1.set_xticks(random_consumption)
#     ax1.set_xticklabels(random_consumption, rotation="vertical")
    ylabel("Optimal PV System Capacity [kW]")
    xlabel("Consumer Monthly Energy use [kWh]")
    grid("on");
    title(string("Optimal System Choice for ", company, " ", tariff, " Consumer (Various Locations)"))
end

# NOTE: be sure to set the appropriate tariff before calling this function
function retrieve_monte_carlo_model_prediction(company, num_samples, tariff, tariff_obj, random_consumption, cap_range)
    mc_filename = string("data/monte_carlo_data/", company, "_", num_samples, ".txt")
    if isfile(mc_filename)
        mc_pv_output = readdlm(mc_filename, '\t', Float64, '\n')
    else
        println("Can't find NSRDB+SAM output")
        return
    end
    
    mc_data = []

    for pv_output in eachcol(mc_pv_output)
        mcPV = -1 # Placeholder because Julia's "Nothing" is strange and I don't understand it yet
        if tariff == "R"
            mcPV = newPVRes(pv_output)
        elseif tariff == "CI"
            mcPV = newPVComInd(pv_output)
        else
            mcPV = newPVTMT(pv_output)
        end
        pv_data = []
        for (ix, co) in enumerate(random_consumption)
            tariff_obj.econsumption = co; get_pmax(tariff_obj);
            new_data = optimal_pv(tariff_obj, mcPV, cap_range, BAC1, tariff_increase = true)
            push!(pv_data, new_data[1][2])
        end
        push!(mc_data, pv_data)
    end
    return mc_data
end