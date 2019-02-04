function street_light(energy::Float64, cost::Float64)
        
    return 40*cost + min(50000,max(0,(energy - 40)))*cost

end

function VAT(energy::Float64, cost::Float64; rate::Float64 = 0.13, cutoff = 280)
    tax = 0.0
    
    if energy > cutoff
        tax = cost*rate
    end
    
    return tax
end

function firefighters(energy::Float64, cost::Float64)
   
    tax = 0.0
    
    if energy > 100
        tax = cost*0.0175 
    elseif energy > 1750
        tax = 1750*(cost/energy)*0.0175
    end
    
    return tax
end