if @isdefined(cnfl)
    pv_output = averaged_monte_carlo_solar_output(cnfl=cnfl)
else
    pv_output = averaged_monte_carlo_solar_output()
end

function newPVRes(pv_output)
    return PVSystem(1.8,
                [171,155,132,115,104,92,96,111,115,125,114,153],
                0.08,
                [(0:3.0, 2000), (3.0:5.0, 1800), (5.0:10.0, 1700), (10.0:100.0, 1500), (100.0:1000.0, 1000)],
                15000,
                pv_output)
end

function newPVComInd(pv_output)
    return PVSystem(10.0,
                [171,155,132,115,104,92,96,111,115,125,114,153],
                0.08,
                [(0:3.0, 2000), (3:5.0, 1800), (5:10.0, 1700), (10.0:100.0, 1500), (100.0:1000.0, 1000)],
                15000,
                pv_output)
end

function newPVTMT(pv_output)
    return PVSystem(30.0,
                [171,155,132,115,104,92,96,111,115,125,114,153],
                0.08,
                [(0:3.0, 2000), (3:5.0, 1800), (5:10.0, 1700), (10.0:100.0, 1500), (100.0:1000.0, 1000)],
                15000,
                pv_output)
end


PVRes = newPVRes(pv_output)

PVComInd = newPVComInd(pv_output)

PVTMT = newPVTMT(pv_output)

#Financials for the system
BAC1 = Financial(0.045, 0.085, 5, 0.25, 600.0);

discount_factor = [(1/(1+0.0406)^ix) for ix in 1:10]