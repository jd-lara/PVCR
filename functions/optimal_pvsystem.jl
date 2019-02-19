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