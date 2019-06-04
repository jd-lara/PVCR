residential = Residential(20, 550, -0.005, nothing,
                        [0.4, 0.3, 0.4, 0.48, 0.55, 0.63, 0.55, 0.65, 0.68, 0.7, 0.75, 0.81, 0.78, 0.72, 0.68, 0.64, 0.62, 0.65, 0.88, 0.95, 0.88, 0.75, 0.6, 0.45],
                        R_ICE,
                        10,
                        0.0);

commercial = CommIndus(20, 5000, 0.0, nothing,
                        [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.875, 0.8125, 0.6875, 1.0, 0.9375, 0.875, 0.8125, 0.8125, 0.8125, 0.75, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25],
                        CI_ICE,
                        10,
                        0.10);

industrial = CommIndus(20, 8050, 0.0, nothing,
                        [0.37037037, 0.37037037, 0.37037037, 0.37037037, 0.666666667, 0.666666667, 0.666666667, 0.666666667, 1.0, 1.0, 1.0, 0.666666667, 0.66666666, 0.666666667, 0.666666667, 0.666666667, 1.0, 1.0, 0.37037037, 0.37037037, 0.37037037, 0.37037037, 0.37037037, 0.37037037],
                        CI_ICE,
                        10,
                        0.10);

mediumvoltage = TMT(20, 20550, -0.005, nothing,
                        [0.37037037, 0.37037037, 0.37037037, 0.37037037, 0.666666667, 0.666666667, 0.666666667, 0.766666667, 1.0, 1.0, 1.0, 0.766666667, 0.66666666, 0.666666667, 0.666666667, 0.766666667, 1.0, 1.0, 1.0, 0.77037037, 0.37037037, 0.37037037, 0.37037037, 0.37037037],
                        TMT_ICE,
                        10,
                        0.10);

get_pmax(residential);
get_pmax(commercial);
get_pmax(industrial);
get_pmax(mediumvoltage);
