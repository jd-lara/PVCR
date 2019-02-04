#=
function print_tariff(tariff::Tariff)
    
    if tariff.category == "Residential"
        x = []
        y = []
        for block in tariff.e_cost 
            x = vcat(x,block[1])
            y = vcat(y, block[2]*ones(length(block[1])))
        end
    
    elseif tariff.category == "Residential"    
    
    end    
        
    
        
    plot(x,y)

end
=#