function period_pay(P::Float64, rate::Float64, n::Int64)

 return (P*rate*(1.0+rate)^n)/((1.0+rate)^n -1)

end

function amortize(rate::Float64, n::Int64, P::Float64)
 balance = Array{Float64,1}()
 p = period_pay(P,rate,n)
    
 for k in 1:n
     btmp = P*(1.0+rate)^k - p*(1.0-(1.0+rate)^k)/(-rate)
     push!(balance,btmp)
 end

 intp = vcat([P]*rate, balance[1:end-1]*rate)
 balance = balance[1:end]
 principal_paid = p .- intp

 return  principal_paid, intp, balance, p
    
end

function PV_netcost(consumer::Consumer, system::PVSystem, finance::Financial)
    
    if system.capacity > 0.0
        PV = PVCost(system,finance.XhR)
        payment = amortize(finance.apr/12, finance.term*12, PV)
    else
        #dirty way to have 0 payments, needs some fixing later
        payment = amortize(finance.apr/12, finance.term*12, 0.0)    
    end
    
    netsavings = Array{Float64,2}(undef,12,finance.term)
    
    for y in 1:finance.term
        ebalance = annual_energy_balance(consumer, system, print_output=false);
        
        for m in 1:12

            bill = monthly_bill(ebalance[m], consumer, print_output=false)

            netsavings[m,y] = (bill["savings"] - payment[4])

        end
        
    end

    return netsavings
        
end