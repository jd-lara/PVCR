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

function PV_cashflow(consumer::Consumer, system::PVSystem, financial_terms::Financial; tariff_increase=true)
    
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
    
function optimal_pv(consumer::Consumer, system::PVSystem, capacity_range, financial_terms::Financial; tariff_increase=true)
    
    results = Array{Float64,2}(undef, length(capacity_range), 2)    
        
    for (ix,cap) in enumerate(capacity_range)
            system.capacity = cap
            results[ix,1] = cap;
            
            cash_flows = PV_cashflow(consumer, system, financial_terms, tariff_increase=tariff_increase)
            annuities = sum(cash_flows,dims=1)
            if sum(annuities[1:5]) < 0 
                continue
            end
            results[ix,2] = npv(annuities, consumer.rate_return) 
    end
        
    return findmax(results[:,2]), results
    
end