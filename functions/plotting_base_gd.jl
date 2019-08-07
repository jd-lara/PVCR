# Year  Month  Energy generated?  Energy Desposited?  Withdrawn energy?     Amount of energy used     Company   Tariff number   
# A       B          C                     D               E                         F                 G               H               
# ANNO, MES,  ENERGIA_GENERADA,  ENERGIA_DEPOSITADA, ENERGIA_RETIRADA  IMPORTE_POR_ENERGIA_RETIRADA,  EMPRESA, CODIGO_TARIFA,

# Tariff description   Total consumption
#         I                 J                K                       L               M                 N               O
# CODIGO_TARIFA1,     TOTAL_CONSUMO_KWH, TOTAL_IMPORTE_ENE, Suma de DISTRITO, Recuento de DISTRITO,  Provincia1,  CONSUMO_NATURAL,  SECTOR,  Data_Check

using Plots

pyplot()

tariff_names = Dict([(1, "Residential"),
(2, "Residencial horaria"),
(4, "Commercial y services mon-mica"),
(5, "Comercios y servicios con potencia"),
(6, "Industrial mon-mica"),
(7, "Industrial con potencia"),
(8, "Preferencial mon-mica"),
(9, "Preferencial con potencia"),
(10, "Promocional mon—mica"),
(11, "Promocional con potencia"),
(12, "Media tensi—n a")])

# This function creates new arrays that contains all values with valid ENERGIA_GENERADA and CONSUMO_NATURAL
function create_consumption_and_generation_arrays(utility_bill_df)    
    nothing_missing_df = filter(row -> (!ismissing(row.ENERGIA_GENERADA) && !ismissing(row.CONSUMO_NATURAL)), utility_bill_df)
    string_to_float(str) = tryparse(Float64, str)
    consumption_and_generation = [[],[]]
    consumption_and_generation[1] = map(string_to_float, nothing_missing_df[:CONSUMO_NATURAL])
    consumption_and_generation[2] = collect(skipmissing(nothing_missing_df[:ENERGIA_GENERADA]))
    return consumption_and_generation
end
    
# This function takes in consumption and generation arrays, and plots them
function plot_consumption_and_generation(consumption_and_generation, tariff_name, company_name)
    # Plot out the actual PV system sizes that people have based on their energy bills
    the_plot = plot(consumption_and_generation[1], consumption_and_generation[2], ".")
#     legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    ylabel("PV System Capacity [kW]")
    xlabel("Consumer Monthly Energy use [kWh]")
    grid("on");
    title(string("PV System Capacity for ", company_name, " Consumer with Tariff ", tariff_name))
    plt.tight_layout()
#     println(typeof(the_plot))
    return the_plot
end

function plot_all_tariffs_per_company(company_data_split_by_tariff, company_name)
    fig, ax = plt.subplots(nrows=12, ncols=1, figsize=(10, 50))
    for i = 1:12
        if i != 3 # Since there is no tariff 3 present
            plt.sca(ax[i])
            plot_consumption_and_generation(create_consumption_and_generation_arrays(company_data_split_by_tariff[i]), tariff_names[i], company_name)
        end
    end
end