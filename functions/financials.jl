function rate_transform(annual_rate::Float64, periods::Int64)

    return (1+annual_rate)^(1/periods) -1 #monthly rate
end

function period_pay(P::Float64, rate::Float64, n::Int64)

 return (P*rate*(1.0+rate)^n)/((1.0+rate)^n -1)

end

function amortize(P::Float64, rate::Float64, n::Int64)
 balance = []
 p = period_pay(P,rate,n)
 for k in 1:n
     btmp = P*(1.0+rate)^k - p*(1.0-(1.0+rate)^k)/(-rate)
     push!(balance,btmp)
 end

 intp = vcat([0], balance[1:end-1]*rate)
 balance = balance[1:end-1]
 principal_paid = p - intp

 return balance, intp, principal_paid
end