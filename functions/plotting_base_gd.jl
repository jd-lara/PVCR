# Year  Month  Energy generated?  Energy Desposited?  Withdrawn energy?     Amount of energy used     Company   Tariff number   
# A       B          C                     D               E                         F                 G               H               
# ANNO, MES,  ENERGIA_GENERADA,  ENERGIA_DEPOSITADA, ENERGIA_RETIRADA  IMPORTE_POR_ENERGIA_RETIRADA,  EMPRESA, CODIGO_TARIFA,

# Tariff description   Total consumption
#         I                 J                K                       L               M                 N               O
# CODIGO_TARIFA1,     TOTAL_CONSUMO_KWH, TOTAL_IMPORTE_ENE, Suma de DISTRITO, Recuento de DISTRITO,  Provincia1,  CONSUMO_NATURAL,  SECTOR,  Data_Check

using DataFrames
using PyPlot
using GLM

tariff_categories = ["Residential", "Commercial Industrial", "Medium Voltage"]

# Tariff types:
# 1: Residential
# 2: Residencial horaria
# 4: Commercial y services mon-mica
# 5: Comercios y servicios con potencia
# 6: Industrial mon-mica
# 7: Industrial con potencia
# 8: Preferencial mon-mica
# 9: Preferencial con potencia
# 10: Promocional mon—mica
# 11: Promocional con potencia
# 12: Media tensi—n a
tariff_category_mappings = Dict([
        (1, tariff_categories[1]),
        (4, tariff_categories[2]),
        (5, tariff_categories[2]),
        (6, tariff_categories[2]),
        (7, tariff_categories[2]),
        (12, tariff_categories[3])
        ])

if !@isdefined pv_output
    if @isdefined(cnfl)
        pv_output = monte_carlo_solar_output(cnfl=cnfl)
    else
        pv_output = monte_carlo_solar_output()
    end
end

output_by_month = Array{Float64}(undef,12)
# First entry for looping purposes only
days_per_month = [0,31,28,31,30,31,30,31,31,30,31,30,31]

for i=1:12
    output_by_month[i] = sum(pv_output[sum(days_per_month[1:i])*24+1:sum(days_per_month[1:i+1])*24])
end     

# This function cleans up the data for a particular utility+tariff
function create_consumption_and_installation_arrays(utility_bill_df)    
    # Only keep entries with valid ENERGIA_GENERADA and CONSUMO_NATURAL
    cleaned_df = filter(row -> (!ismissing(row.ENERGIA_GENERADA) && !ismissing(row.CONSUMO_NATURAL)), utility_bill_df)
    
    # Only keep entries with PV system output > 100 kWh per month (this would mean it's a roughly 1kW system)
    string_to_float(str) = tryparse(Float64, str)
    cleaned_df[:CONSUMO_NATURAL] = map(string_to_float, cleaned_df[:CONSUMO_NATURAL])
    cleaned_df = filter(row -> (row.CONSUMO_NATURAL > 100), cleaned_df)
    
    # Construct consumption and installation arrays
    # Only keep values where installation is >= 1
    consumption_array = Array{Float64}(undef,0)
    installation_array = Array{Float64}(undef,0)
    for r in eachrow(cleaned_df)
        month = r.MES
        generation = r.ENERGIA_GENERADA
        installation = generation / output_by_month[month]
        if installation >= 1
            push!(installation_array, installation)
            push!(consumption_array, r.CONSUMO_NATURAL)
        end
    end
        
    return [consumption_array, installation_array]
end

# This function takes in consumption and installation arrays, and plots them
function plot_consumption_and_installation(consumption_and_installation, tariff_name, company_name)
    plt.figure()
    # Plot out the actual PV system sizes that people have based on their energy bills
    the_plot = plot(consumption_and_installation[1], consumption_and_installation[2], ".")
    ylabel("PV System Capacity [kW]")
    xlabel("Consumer Monthly Energy use [kWh]")
    grid("on");
    title(string("PV System Capacity for ", company_name, " Consumer with Tariff ", tariff_name))
    return the_plot
end

function plot_base_GD_vs_economically_rational(consumption_and_installation, tariff_name, company_name, consumption, model_predictions)
    fig = plt.figure()
    ax1 = fig.add_subplot(111)
    # Plot out the actual PV system sizes that people have based on their energy bills
    ax1.scatter(consumption_and_installation[1], consumption_and_installation[2], marker=".", label = string("Actual PV System Installation for ", tariff_name, " Consumer"))
    # Plot out the installation predicted by the economically rational model
    ax1.plot(consumption, model_predictions, c = "r", label = string("Optimal PV System for ", tariff_name, " Consumer"))
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    ylabel("PV System Capacity [kW]")
    xlabel("Consumer Monthly Energy use [kWh]")
    grid("on");
    title(string("PV System Capacity for ", company_name, " Consumer with Tariff ", tariff_name))
end
  
function plot_single_tariff_category_per_company_with_model_prediction(company_data, tariff_category, company_name, consumption, model_predictions)
    company_data_split_by_tariff_category = Array{DataFrame}(undef,3)

    # Loop through all tariffs that we care about
    for (tariff_num, tariff_category) in tariff_category_mappings
        next_value = filter(row -> (!ismissing(row.CODIGO_TARIFA) && row.CODIGO_TARIFA == string(tariff_num)), company_data)
        category_index = findfirst(t -> t == tariff_category, tariff_categories)
        if !isassigned(company_data_split_by_tariff_category, category_index)
            company_data_split_by_tariff_category[category_index] = next_value
        else
            append!(company_data_split_by_tariff_category[category_index], next_value)
        end
    end
    
    category_index = findfirst(t -> t == tariff_category, tariff_categories)
    
    plot_base_GD_vs_economically_rational(create_consumption_and_installation_arrays(
                company_data_split_by_tariff_category[category_index]), tariff_categories[category_index], company_name, consumption, model_predictions)
end

function plot_all_tariffs_per_company(company_data, company_name)
    company_data_split_by_tariff_category = Array{DataFrame}(undef,3)

    # Loop through all tariffs that we care about
    for (tariff_num, tariff_category) in tariff_category_mappings
        next_value = filter(row -> (!ismissing(row.CODIGO_TARIFA) && row.CODIGO_TARIFA == string(tariff_num)), company_data)
        category_index = findfirst(t -> t == tariff_category, tariff_categories)
        if !isassigned(company_data_split_by_tariff_category, category_index)
            company_data_split_by_tariff_category[category_index] = next_value
        else
            append!(company_data_split_by_tariff_category[category_index], next_value)
        end
    end
    
    # Loop through and plot each tariff category
    for i in 1:3
        plot_consumption_and_installation(create_consumption_and_installation_arrays(
                company_data_split_by_tariff_category[i]), tariff_categories[i], company_name)
    end
end

function plot_tariff_category_with_two_regressions(company_data, tariff_category, company_name, consumption, model_predictions, inflection_point=1500)
    
    fig = plt.figure()
    ax1 = fig.add_subplot(111)

    
    # Collect the tariff-relevant data
    tariff_data = Array{DataFrame}(undef,1)
    for (tariff_num, tariff_cat) in tariff_category_mappings
        if tariff_cat != tariff_category
            continue
        end
        tariff_df = filter(row -> (!ismissing(row.CODIGO_TARIFA) && row.CODIGO_TARIFA == string(tariff_num)), company_data)
        if !isassigned(tariff_data, 1)
            tariff_data[1] = tariff_df
        else
            append!(tariff_data[1], tariff_df)
        end
    end
    
    # Get least-squares regression of the data
    t_consumption, t_installation = create_consumption_and_installation_arrays(tariff_data[1])
    combined = DataFrame()
    combined[:CONSUMPTION] = t_consumption
    combined[:INSTALLATION] = t_installation

    function map_to_float(str)
        try
            convert(Float64, str) 
        catch 
            return(NA) 
        end
    end
    
    combined[:CONSUMPTION] = map(map_to_float, combined[:CONSUMPTION])
    combined[:INSTALLATION] = map(map_to_float, combined[:INSTALLATION])

    combined_1 = filter(row -> (row.CONSUMPTION <= inflection_point), combined)
    data_b_1, data_m_1 = coef(lm(@formula(INSTALLATION ~ CONSUMPTION), combined_1))
    t_consumption_1 = combined_1[:CONSUMPTION]
    t_installation_1 = combined_1[:INSTALLATION]
    ax1.scatter(t_consumption_1, t_installation_1, c="g", marker=".", alpha=0.2, label = string("Actual PV System Installation for a ", tariff_category, " Consumer using less than ", inflection_point, " kWh per month"))    
    
    combined_2 = filter(row -> (row.CONSUMPTION > inflection_point), combined)
    data_b_2, data_m_2 = coef(lm(@formula(INSTALLATION ~ CONSUMPTION), combined_2))
    t_consumption_2 = combined_2[:CONSUMPTION]
    t_installation_2 = combined_2[:INSTALLATION]
    ax1.scatter(t_consumption_2, t_installation_2, c="m", marker=".", alpha=0.2, label = string("Actual PV System Installation for a ", tariff_category, " Consumer using more than ", inflection_point, " kWh per month"))
    
    x_vals = ax1.get_xlim()
    x_vals_1 = x_vals[1]:(inflection_point-x_vals[1])/100:inflection_point
    x_vals_2 = inflection_point:(x_vals[2]-inflection_point)/100:x_vals[2]
    y_vals_1 = data_m_1 * x_vals_1 .+ data_b_1
    y_vals_2 = data_m_2 * x_vals_2 .+ data_b_2
    ax1.plot(x_vals_1, y_vals_1, "--", c="g", label = string("Least-squares regression for actual installation of consumers using less than ", inflection_point, " kWh per month"))
    ax1.plot(x_vals_2, y_vals_2, "--", c="m", label = string("Least-squares regression for actual installation of consumers using more than ", inflection_point, " kWh per month"))
    
    # Run a regression on the model data
    ax1.plot(consumption, model_predictions, c = "r", label = string("Optimal PV System for ", tariff_category, " Consumer"))
#     model_df = DataFrame()
#     model_df[:CONSUMPTION] = consumption
#     model_df[:PREDICTIONS] = model_predictions
#     model_df[:CONSUMPTION] = map(map_to_float, model_df[:CONSUMPTION])
#     model_df[:PREDICTIONS] = map(map_to_float, model_df[:PREDICTIONS])

#     model_df_1 = filter(row -> (row.CONSUMPTION <= inflection_point), model_df)
#     model_b_1, model_m_1 = coef(lm(@formula(PREDICTIONS ~ CONSUMPTION), model_df_1))
#     y_vals_model_1 = model_m_1 * x_vals_1 .+ model_b_1
#     ax1.plot(x_vals_1, y_vals_model_1, "--", c="r", label = string("Least-squares regression for model prediction below inflection point"))

    
#     model_df_2 = filter(row -> (row.CONSUMPTION > inflection_point), model_df)
#     model_b_2, model_m_2 = coef(lm(@formula(PREDICTIONS ~ CONSUMPTION), model_df_2))
#     y_vals_model_2 = model_m_2 * x_vals_2 .+ model_b_2
#     ax1.plot(x_vals_2, y_vals_model_2, "--", c="r", label = string("Least-squares regression for model prediction above inflection point"))

    
    



    
    title(string("PV System Capacity for ", company_name, " Consumer with Tariff ", tariff_category))
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
#     colors = ["g", "c", "m", "y", "k"]
    
    
end

##################################

function plot_segmented_tariff_category_with_regression(company_data, tariff_category, company_name, consumption, model_predictions, regression_limit=0, individual_regressions=false)
    colors = ["g", "c", "m", "y", "k"]
    
    individual_tariffs = Dict{Integer,DataFrame}()
    # Loop through all tariffs that we care about
    for (tariff_num, tariff_cat) in tariff_category_mappings
        # Only look at tariffs within our specified tariff category
        if tariff_cat != tariff_category
            continue
        end
        tariff_df = filter(row -> (!ismissing(row.CODIGO_TARIFA) && row.CODIGO_TARIFA == string(tariff_num)), company_data)
        individual_tariffs[tariff_num] = tariff_df
    end
    
    fig = plt.figure()
    ax1 = fig.add_subplot(111)
    title(string("PV System Capacity for ", company_name, " Consumer with Tariff ", tariff_category))
    
    all_tariff_data = Array{DataFrame}(undef,1)
    
    individual_consumption_and_installations = []
    
    for (tariff_num, tariff_df) in individual_tariffs
        if !isassigned(all_tariff_data, 1)
            all_tariff_data[1] = tariff_df
        else
            append!(all_tariff_data[1], tariff_df)
        end
        t_consumption, t_installation = create_consumption_and_installation_arrays(tariff_df)
        plot_color = pop!(colors)
        # Plot out the actual PV system sizes that people have based on their energy bills
        ax1.scatter(t_consumption, t_installation, c=plot_color, marker=".", alpha=0.5, label = string("Actual PV System Installation for a ", tariff_category, " Number ", tariff_num, " Consumer"))
        if individual_regressions == true
            push!(individual_consumption_and_installations, (t_consumption, t_installation, tariff_num, plot_color))
        end
    end
    
    # Get least-squares regression of the data
    all_con, all_ins = create_consumption_and_installation_arrays(all_tariff_data[1])
    combined = DataFrame()
    combined[:CONSUMPTION] = all_con
    combined[:INSTALLATION] = all_ins

    function map_to_float(str)
        try
            convert(Float64, str) 
        catch 
            return(NA) 
        end
    end
    
    combined[:CONSUMPTION] = map(map_to_float, combined[:CONSUMPTION])
    combined[:INSTALLATION] = map(map_to_float, combined[:INSTALLATION])

    # Run regression on the entire dataset, and plot.
    data_b, data_m = coef(lm(@formula(INSTALLATION ~ CONSUMPTION), combined))
    x_vals = ax1.get_xlim()
    x_vals = x_vals[1]:x_vals[2]-x_vals[1]/100:x_vals[2]
    y_vals = data_m * x_vals .+ data_b
    ax1.plot(x_vals, y_vals, "--", c="b", label = string("Least-squares regression for actual installation"))
    
    # If indicated, also run a regression on a subset of the data
    if regression_limit != 0
        limited_combined = filter(row -> (row.CONSUMPTION <= regression_limit), combined)
        limited_data_b, limited_data_m = coef(lm(@formula(INSTALLATION ~ CONSUMPTION), limited_combined))
        y_vals = limited_data_m * x_vals .+ limited_data_b
        ax1.plot(x_vals, y_vals, "--", c="g", label = string("Least-squares regression for actual installation of consumers using less than ", regression_limit, " kWh per month"))
    end
    
    # Plot out the installation predicted by the economically rational model
    ax1.plot(consumption, model_predictions, c = "r", label = string("Optimal PV System for ", tariff_category, " Consumer"))
    
    # Run a regression on the model data
    model_df = DataFrame()
    model_df[:CONSUMPTION] = consumption
    model_df[:PREDICTIONS] = model_predictions
    
    model_df[:CONSUMPTION] = map(map_to_float, model_df[:CONSUMPTION])
    model_df[:PREDICTIONS] = map(map_to_float, model_df[:PREDICTIONS])

    model_data_b, model_data_m = coef(lm(@formula(PREDICTIONS ~ CONSUMPTION), model_df))
    y_vals = model_data_m * x_vals .+ model_data_b
    ax1.plot(x_vals, y_vals, "--", c="c", label = string("Least-squares regression for model prediction"))
    legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
    ylabel("PV System Capacity [kW]")
    xlabel("Consumer Monthly Energy use [kWh]")
    grid("on");
    
    if individual_regressions == true
        num_figures = length(individual_consumption_and_installations)
        fig = plt.figure(figsize=(num_figures, 5*num_figures))
        colors = ["g", "c", "m", "y", "k"]
        for i in 1:length(individual_consumption_and_installations)
            new_axis = fig.add_subplot(num_figures, 1, i)
            for j in 1:length(individual_consumption_and_installations)
                t_consumption, t_installation, tariff_num, plot_color = individual_consumption_and_installations[j]
                new_axis.scatter(t_consumption, t_installation, c=plot_color, marker=".", alpha=0.5)
            end
            t_consumption, t_installation, tariff_num, plot_color = individual_consumption_and_installations[i]
            combined = DataFrame()
            combined[:CONSUMPTION] = t_consumption
            combined[:INSTALLATION] = t_installation
            # Run regression on the specific sub-tariff, and plot.
            data_b, data_m = coef(lm(@formula(INSTALLATION ~ CONSUMPTION), combined))
            x_vals = new_axis.get_xlim()
            x_vals = x_vals[1]:x_vals[2]-x_vals[1]/100:x_vals[2]
            y_vals = data_m * x_vals .+ data_b
            new_axis.plot(x_vals, y_vals, "--", c=plot_color, label = string("Least-squares regression for actual installation for tariff number ", tariff_num))
            legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.);
            ylabel("PV System Capacity [kW]")
            xlabel("Consumer Monthly Energy use [kWh]")
            grid("on");
        end
    end
    
    
end