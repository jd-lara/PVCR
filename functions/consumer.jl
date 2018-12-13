function consumertotal_energy(consumer::Consumer, periods::Int64)

    period_energy = []

    for k in 0:periods-1
        monthly_energy = consumer.econsumption*(1+consumer.growth)^k*tariff.behaviour
        push!(period_energy,monthly_energy')
    end

    return period_energy

end

function get_pmax(consumer::T) where {T <: Consumer}

    days_p_month = [31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    peak_power = Array{Float64,1}(undef,12)
    cap_factor = sum(consumer.load_curve)/24

    for i in 1:12

        e_monthly = consumer.econsumption*consumer.tariff.behaviour[i]

        peak_power[i]= e_monthly/(cap_factor*days_p_month[i]*24)

    end

    consumer.peak_power = peak_power;

end
