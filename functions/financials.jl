function irr(annuity::Array{Float64})
    
    if sum(annuity) <= 0.0
        return 0.0
    end
    
    tvmnpv(i,annuity)=begin
         n=collect(1:length(annuity));
         sum(annuity./(1+i).^n)
        end
    
    f(x)=tvmnpv(x, annuity)
    
    return fzero(f, [0.0, 1.0])
    
end

function npv(annuities::Array{Float64}, rate::Float64)
    pv = 0.0
    
    for (ix,p) in enumerate(annuities)
        
        pv += p/(1+rate)^(ix-1)
        
    end
    
    return pv
    
end

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
        