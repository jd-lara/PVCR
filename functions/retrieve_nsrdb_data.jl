using PyCall
using PyPlot
using DelimitedFiles
using StatsBase
using ArchGDAL
const AG = ArchGDAL
using Dates
using DataFrames

const ICE_SAMPLE_NUM = 100
const CNFL_SAMPLE_NUM = 100

# Getting filenames for files where we may have locally saved datasets of one solar year's worth of PV system generation data
function get_mc_data_filename(num_samples, cnfl)
    provider = length(cnfl) == 0 ? "ALL" : (cnfl[1] == true ? "CNFL" : "ICE")
    num_samples = (length(cnfl) == 1) ? (cnfl[1] == true ? min(num_samples, CNFL_SAMPLE_NUM) : min(num_samples, ICE_SAMPLE_NUM)) : num_samples
    mc_filename = string("data/monte_carlo_data/", provider, "_", string(num_samples), ".txt")
    return (num_samples, mc_filename)
end

# Getting filenames for files where we may have locally saved the coordinates corresponding to the above PV system generation datasets
function get_mc_coords_filename(num_samples, cnfl)
    provider = length(cnfl) == 0 ? "ALL" : (cnfl[1] == true ? "CNFL" : "ICE")
    num_samples = (length(cnfl) == 1) ? (cnfl[1] == true ? min(num_samples, CNFL_SAMPLE_NUM) : min(num_samples, ICE_SAMPLE_NUM)) : num_samples
    mc_filename = string("data/monte_carlo_data/", provider, "_", string(num_samples), "_COORDS.txt")
    return mc_filename
end

# Tries to get those preexisting files, and averages all of the PV output timeseries with a strict equal weighting, in order to get an “average PV system output”. If the files aren’t there, it will call the next function, to make the NSRDB+SAM calls
function averaged_monte_carlo_solar_output(;num_samples=100, cnfl=[])
    # Get the individual data points for various locations across the country
    num_samples, mc_filename = get_mc_data_filename(num_samples, cnfl)
    if isfile(mc_filename)
        mc_pv_output = readdlm(mc_filename, '\t', Float64, '\n')
    else
        println("have to generate new data")
        mc_pv_output, mc_locations = monte_carlo_solar_output(num_samples, cnfl)
        open(mc_filename, "w") do io
           writedlm(io, mc_pv_output)
        end
        coords_filename = get_mc_coords_filename(num_samples, cnfl)
        open(coords_filename, "w") do io
           writedlm(io, mc_locations)
        end
    end
    
    # Average all of them, to return a normalized data set for a hypothetical "solar year"
    return sum(mc_pv_output, dims=2) ./ num_samples
end

# Calling to NSRDB+SAM to obtain Monte Carlo dataset of solar years
function monte_carlo_solar_output(num_samples, cnfl; use_cached=false)
    # Has an option to try and read from a cache, for testing
    if (use_cached)
        _, mc_filename = get_mc_data_filename(num_samples, cnfl)
        mc_coords_filename = get_mc_coords_filename(num_samples, cnfl)
        if isfile(mc_filename) && isfile(mc_coords_filename)
            mc_pv_output = readdlm(mc_filename, '\t', Float64, '\n')
            mc_coords = readdlm(mc_filename, '\t', Float64, '\n')
            return (mc_pv_output, mc_coords)
        end
    end
    
    # Loads GIS files for population density (to weight the location sampling), the CNFL area (for CNFL vs ICE split), the protected area (to exclude), the overall map of Costa Rica (to make sure that generated points are within the nation's borders)
    pop_density_filename = "data/distritos/distritos2008crtm05.shp"
    cnfl_gis_filename = "data/area_CNFL"
    area_protegidas_gis_filename = "data/Areaprotegidas"
    cr_map_filename = "data/CRI_adm/CRI_adm0.shp"
    ice_gis_filename = "data/fEmpresaDistribuidoras_2020"
    pv_outputs_array = Array{Float64,1}()
    
    coords = []

    AG.registerdrivers() do
        # Get data corresponding to the location of CNFL-serviced districts, for later location sampling
        AG.read(cnfl_gis_filename) do cnfl_gis_dataset
            cnfl_gis = AG.getlayer(cnfl_gis_dataset, 0)
            
            # Get data corresponding to the map of ICE service territory, for later location sampling
            AG.read(ice_gis_filename) do ice_gis_dataset
                ice_gis = AG.getlayer(ice_gis_dataset, 0)
            
                # Get data corresponding to the location of protected areas, to exclude from all location sampling
                AG.read(area_protegidas_gis_filename) do area_protegidas_gis_dataset
                    area_protegidas_gis = AG.getlayer(area_protegidas_gis_dataset, 0)

                    # The above 2 GIS data files are in a format which does not line up with latitude and longitude.
                    # We will run a transform to project it into lat-long
                    AG.importPROJ4("proj +proj=longlat") do target
                        
                        # Get population density information
                        # This can either be derived from cnfl_gis, or we need a nation-wide district file
                        district_centroids = []
                        district_populations = []
                            
                        if isassigned(cnfl, 1) && cnfl[1]
                            num_features = AG.nfeature(cnfl_gis)
                            for i in 1:(num_features)
                                ArchGDAL.getfeature(cnfl_gis, i - 1) do feature
                                    male_population = AG.asint(feature, AG.getfieldindex(feature, "POB_2000_M"))
                                    female_population = AG.asint(feature, AG.getfieldindex(feature, "POB_2000_H"))
                                    total_population = male_population + female_population
                                    push!(district_populations, total_population)

                                    geom = AG.getgeomfield(feature, 0)
                                    source = AG.getspatialref(geom)
                                    AG.createcoordtrans(source, target) do transform
                                        AG.transform!(geom, transform)
                                        centroid = AG.centroid(geom)
                                        push!(district_centroids, centroid)
                                    end
                                end
                            end
                        else
                            AG.read(pop_density_filename) do districts_gis_dataset
                                districts_gis = AG.getlayer(districts_gis_dataset, 0)
                                println(districts_gis)
                                num_features = AG.nfeature(districts_gis)
                                for i in 1:(num_features)
                                    ArchGDAL.getfeature(districts_gis, i - 1) do feature
                                        male_population = AG.asint(feature, AG.getfieldindex(feature, "POB_2000_M"))
                                        female_population = AG.asint(feature, AG.getfieldindex(feature, "POB_2000_H"))
                                        total_population = male_population + female_population
                                        push!(district_populations, total_population)

                                        geom = AG.getgeomfield(feature, 0)
                                        source = AG.getspatialref(geom)
                                        AG.createcoordtrans(source, target) do transform
                                            AG.transform!(geom, transform)
                                            centroid = AG.centroid(geom)
                                            push!(district_centroids, centroid)
                                        end
                                    end
                                end
                            end
                        end

                        # Convert population density into a set of weights for an Empirical CDF
                        weights = FrequencyWeights(collect(Iterators.flatten(district_populations)))

                        # Run a weighted sampling to obtain the coordinates to sample NSRDB from

                        # Obtain sample PV output for each location
                        while length(coords) < num_samples

                            possible_coords = sample(district_centroids, weights)

                            # Determine whether these coordinates have been already added, or are part of excluded parts of CR
                            if !in(possible_coords, coords)
                                can_add = false
                                ag_coords = possible_coords

                                # Is this point even on land, or is it over the ocean?
                                AG.read(cr_map_filename) do cr_map_dataset
                                    cr_map_gis = AG.getlayer(cr_map_dataset, 0)
                                    num_features = AG.nfeature(cr_map_gis)
                                    for i in 1:(num_features)
                                        ArchGDAL.getfeature(cr_map_gis, i - 1) do feature
                                            geom = AG.getgeomfield(feature, 0)
                                            if AG.contains(geom, ag_coords)
                                                can_add = true
                                            end
                                        end
                                    end
                                end

                                if !can_add
                                    continue
                                end

                                # Add a conditional check for whether the location is within CNFL or ICE service area
                                # Only do this when [cnfl] is defined: otherwise, assume we want national data
                                # If this is CNFL, we're using the CNFL districts so it's guaranteed to be correct
                                if isassigned(cnfl, 1) && !cnfl[1]
                                    can_add = false
                                    ArchGDAL.getfeature(ice_gis, 4) do feature
                                        geom = AG.getgeomfield(feature, 0)
                                        source = AG.getspatialref(geom)
                                        AG.createcoordtrans(source, target) do transform
                                            AG.transform!(geom, transform)
                                            if AG.contains(geom, ag_coords)
                                                can_add = true
                                                println(string(possible_coords, " is within the ICE area"))
                                            end
                                        end
                                    end

                                    if !can_add
                                        continue
                                    end
                                end

                                # Check that the generated point isn't in a nationally protected area/national forest
                                num_features = AG.nfeature(area_protegidas_gis)
                                for i in 1:(num_features)
                                    ArchGDAL.getfeature(area_protegidas_gis, i - 1) do feature
                                        geom = AG.getgeomfield(feature, 0)
                                        source = AG.getspatialref(geom)
                                        AG.createcoordtrans(source, target) do transform
                                            AG.transform!(geom, transform)
                                            if AG.contains(geom, ag_coords)
                                                println(string("but ", possible_coords, " is within a protected area so we can't use it"))
                                                can_add = false # Not using this point because it is in an uninhabited location
                                            end
                                        end
                                    end
                                end

                                if !can_add
                                    continue
                                end

                                # Make the call out to NSRDB + SAM to obtain pv_output for that location
                                pv_output = -1
                                try
                                    lat, lon = AG.gety(possible_coords, 0), AG.getx(possible_coords, 0)
                                    pv_output = convert(Array{Float64,1},get_nsrdb_sam_pv_output(lat=lat, lon=lon))
                                catch e
                                    println("but the NSRDB call failed, so we won't use it")
                                    can_add = false # Not using this point because NSRDB doesn't like it
                                end

                                if can_add
                                    push!(coords, possible_coords)
                                    println(length(coords))
                                    if length(pv_outputs_array) == 0
                                        append!(pv_outputs_array, pv_output)
                                    else
                                        pv_outputs_array = hcat(pv_outputs_array, pv_output)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    # Return the outputs of SAM, along with a DataFrame of all of the coordinates for future reference
    coords = convert(Array{Float64,2}, DataFrame(Latitude = [AG.gety(coord, 0) for coord in coords], Longitude = [AG.getx(coord, 0) for coord in coords]))
    return (pv_outputs_array, coords)
    
end

# A wrapper to either call get_nsrdb_sam_df, or if we want to skip all this and just return a hardcoded value
function get_nsrdb_sam_pv_output(;lat=9.817934, lon=-84.070552, tz=-6, year=2010, pipeline=true)
    if pipeline == true
        nsrdb_sam_df = get_nsrdb_sam_df(lat, lon, tz, year)
        pv_output = values(nsrdb_sam_df["Generation"])
    else
        pv_output=readdlm("data/pv_output.txt", '\t', Float64, '\n')
    end
    return pv_output
end
   
# Obtain the NSRDB request URL, and invoke the python function which will actually call to the NREL services
function get_nsrdb_sam_df(lat, lon, tz, year)
    request_url = get_nsrdb_request_url(lat, lon, year);
    py"""
    import sys
    sys.path.insert(0, ".")
    sys.path.insert(0, "./functions")
    """
    call_nsrdb_and_ssc = pyimport("nsrdb_python")["call_nsrdb_and_ssc"];
    nsrdb_sam_df = call_nsrdb_and_ssc(request_url, lat, lon, tz);
    return nsrdb_sam_df;
    end

# Construct the URL to use to get the NSRDB data (this requires an external file with credentials)
function get_nsrdb_request_url(lat,lon,year)
    # Declare all variables as strings. Spaces must be replaced with "+", i.e., change "John Smith" to "John+Smith".

    # Set the attributes to extract (e.g., dhi, ghi, etc.), separated by commas.
    attributes = "ghi,dhi,dni,wind_speed,air_temperature,solar_zenith_angle"

    # Set leap year to true or false. True will return leap day data if present, false will not.
    leap_year = "false"

    # Set time interval in minutes, i.e., "30" is half hour intervals. Valid intervals are 30 & 60.
    interval = "60"

    # Specify Coordinated Universal Time (UTC), "true" will use UTC, "false" will use the local time zone of the data.
    # NOTE: In order to use the NSRDB data in SAM, you must specify UTC as "false". SAM requires the data to be in the
    # local time zone.
    utc = "false"

    # Have a file named "nrel-credentials.txt", with line-separated
    # - Full+Name
    # - Email address
    # - Your+Affiliation
    # - API Key
    credential_file = open("nrel-credentials.txt")
    nrel_credentials = readlines(credential_file)
    
    # Your full name, use "+" instead of spaces.
    your_name = nrel_credentials[1]

    # Your email address
    your_email = nrel_credentials[2]

    # Your affiliation
    your_affiliation = nrel_credentials[3]

    # You must have an NSRDB api key
    api_key = nrel_credentials[4]
    close(credential_file)

    # Please join our mailing list so we can keep you up-to-date on new developments.
    mailing_list = "false";
    
    # Your reason for using the NSRDB.
    reason_for_use = "data+analysis"

    
    # Declare url string
    url = "http://developer.nrel.gov/api/solar/nsrdb_psm3_download.csv?wkt=POINT($(lon)%20$(lat))&names=$(year)&leap_day=$(leap_year)&interval=$(interval)&utc=$(utc)&full_name=$(your_name)&email=$(your_email)&affiliation=$(your_affiliation)&mailing_list=$(mailing_list)&reason=$(reason_for_use)&api_key=$(api_key)&attributes=$(attributes)";
    
    return url;
end

####################

# Unused function to plot PySAM output
function plot_pysam_output(df, i=5030, j=40)
    plt.style.use("seaborn")
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax2 = ax.twinx()
    ax.plot(df[[:GHI]][i:i+j,:][:1])
    ax.plot(df[[:DNI]][i:i+j,:][:1])
    ax.plot(df[[:DHI]][i:i+j,:][:1])
    ax.plot(df[[Symbol("Solar Zenith Angle")]][i:i+j,:][:1])
    ax2.plot(df[[:Generation]][i:i+j,:][:1], color="y")
    ax.grid()
    ax.set_ylabel("W/m2")
    ax2.set_ylabel("kW")
    ax.legend([:GHI, :DNI, :DHI, Symbol("Solar Zenith Angle")], loc="upper left")
    ax2.legend([:Generation], loc="upper right")
end