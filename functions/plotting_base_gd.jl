# Year  Month  Energy generated?  Energy Desposited?  Withdrawn energy?     Amount of energy used     Company   Tariff number   
# A       B          C                     D               E                         F                 G               H               
# ANNO, MES,  ENERGIA_GENERADA,  ENERGIA_DEPOSITADA, ENERGIA_RETIRADA  IMPORTE_POR_ENERGIA_RETIRADA,  EMPRESA, CODIGO_TARIFA,

# Tariff description   Total consumption
#         I                 J                K                       L               M                 N               O
# CODIGO_TARIFA1,     TOTAL_CONSUMO_KWH, TOTAL_IMPORTE_ENE, Suma de DISTRITO, Recuento de DISTRITO,  Provincia1,  CONSUMO_NATURAL,  SECTOR,  Data_Check

using PyPlot

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

# This function cleans up the data for a particular utility+tariff
function create_consumption_and_generation_arrays(utility_bill_df)    
    # Only keep entries with valid ENERGIA_GENERADA and CONSUMO_NATURAL
    cleaned_df = filter(row -> (!ismissing(row.ENERGIA_GENERADA) && !ismissing(row.CONSUMO_NATURAL)), utility_bill_df)
    
    # Only keep entries with PV system output > 100 kWh per month (this would mean it's a roughly 1kW system)
    string_to_float(str) = tryparse(Float64, str)
    cleaned_df[:CONSUMO_NATURAL] = map(string_to_float, cleaned_df[:CONSUMO_NATURAL])
    cleaned_df = filter(row -> (row.CONSUMO_NATURAL > 100), cleaned_df)
    
    consumption_and_generation = [[],[]]
    consumption_and_generation[1] = cleaned_df[:CONSUMO_NATURAL]
    consumption_and_generation[2] = collect(skipmissing(cleaned_df[:ENERGIA_GENERADA]))
    return consumption_and_generation
end
    
# This function takes in consumption and generation arrays, and plots them
function plot_consumption_and_generation(consumption_and_generation, tariff_name, company_name)
    plt.figure()
    # Plot out the actual PV system sizes that people have based on their energy bills
    the_plot = plot(consumption_and_generation[1], consumption_and_generation[2], ".")
    ylabel("PV System Capacity [kW]")
    xlabel("Consumer Monthly Energy use [kWh]")
    grid("on");
    title(string("PV System Capacity for ", company_name, " Consumer with Tariff ", tariff_name))
    return the_plot
end

function plot_all_tariffs_per_company(company_data_split_by_tariff, company_name)
    for i = 1:12
        if i != 3 # Since there is no tariff 3 present
            plot_consumption_and_generation(create_consumption_and_generation_arrays(company_data_split_by_tariff[i]), tariff_names[i], company_name)
        end
    end
end