pv_output=readdlm("data/pv_output.txt", '\t', Float64, '\n')

PVRes = PVSystem(1.8,
                [171,155,132,115,104,92,96,111,115,125,114,153],
                0.08,
                [(0:3.0, 2000), (3.0:5.0, 1800), (5.0:10.0, 1700), (10.0:100.0, 1500), (100.0:1000.0, 1000)],
                15000,
                pv_output
)

PVComInd = PVSystem(10.0,
                [171,155,132,115,104,92,96,111,115,125,114,153],
                0.08,
                [(0:3.0, 2000), (3:5.0, 1800), (5:10.0, 1700), (10.0:100.0, 1500), (100.0:1000.0, 1000)],
                15000,
                pv_output
)

PVTMT = PVSystem(30.0,
                [171,155,132,115,104,92,96,111,115,125,114,153],
                0.08,
                [(0:3.0, 2000), (3:5.0, 1800), (5:10.0, 1700), (10.0:100.0, 1500), (100.0:1000.0, 1000)],
                15000,
                pv_output
)

#Financials for the system
BAC1 = Financial(0.045, 0.085, 5, 0.25, 600.0);