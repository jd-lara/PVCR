function PVtotal_energy(system::PVSystem, periods::Int64)

    period_energy = []

    for k in 0:periods-1
        monthly_energy = system.capacity*system.pu_energy*(1-system.life_loss)^k
        push!(period_energy,monthly_energy)
    end

    return period_energy

end


function PVCost(system::PVSystem, exr::Float64)

    cost_array = system.cost

    PVSize=system.capacity

    pu_cost=[ref[2] for ref in cost_array if (PVSize > ref[1][1]) & (PVSize <= ref[1][end])][1]

    return pu_cost*PVSize*exr

end
