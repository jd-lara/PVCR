using PyCall
using PyPlot
using DelimitedFiles
using StatsBase
using ArchGDAL
const AG = ArchGDAL
using Dates

function averaged_monte_carlo_solar_output(;num_samples=100, cnfl=[])
    # Get the individual data points for various locations across the country
    provider = length(cnfl) == 0 ? "ALL" : (cnfl[1] == true ? "CNFL" : "ICE")
    mc_filename = string("data/monte_carlo_data/", provider, "_", string(num_samples), ".txt")
    if isfile(mc_filename)
        mc_pv_output = readdlm(mc_filename, '\t', Float64, '\n')
    else
        println("have to generate new data")
        mc_pv_output = monte_carlo_solar_output(num_samples, cnfl)
        open(mc_filename, "w") do io
           writedlm(io, mc_pv_output)
        end
    end
    # Average all of them, to return a normalized data set for a hypothetical "solar year"?
    return sum(mc_pv_output, dims=2) ./ num_samples
end

function monte_carlo_solar_output(num_samples, cnfl)
    pop_density_filename = "data/gpw-v4-population-density-rev11_2020_2pt5_min_tif/gpw_v4_population_density_rev11_2020_2pt5_min.tif"
    cnfl_gis_filename = "data/area_CNFL"
    area_protegidas_gis_filename = "data/Areaprotegidas"
    pv_outputs_array = Array{Float64,1}()

    AG.registerdrivers() do
        # Get data corresponding to the location of CNFL-serviced districts, for later location sampling
        AG.read(cnfl_gis_filename) do cnfl_gis_dataset
            cnfl_gis = AG.getlayer(cnfl_gis_dataset, 0)
            
            # Get data corresponding to the location of protected areas, to exclude from all location sampling
            AG.read(area_protegidas_gis_filename) do area_protegidas_gis_dataset
                area_protegidas_gis = AG.getlayer(area_protegidas_gis_dataset, 0)
                
                # The above 2 GIS data files are in a format which does not line up with latitude and longitude.
                # We will run a transform to project it into lat-long
                AG.importPROJ4("proj +proj=longlat") do target
                
                    # Get data corresponding to population density per ~5km square of the Earth's surface
                    AG.read(pop_density_filename) do pop_dataset
                        pop_band = AG.getband(pop_dataset, 1)

                        # Limit to a bounding box surrounding Costa Rica (excluding Cocos Island National Park)
                        min_lat = 8.040682
                        max_lat = 11.2195684
                        min_lon = -85.956896
                        max_lon = -82.5060208
                        
                        # Alternate bounding box for CNFL (significantly speeds up point selection)
                        if (isassigned(cnfl, 1) && cnfl[1])
                            min_lat = 9.839327
                            max_lat = 10.160209
                            min_lon = -84.325326
                            max_lon = -83.621292
                        end
                        
                        pop_band_width = AG.width(pop_band)
                        pop_band_height = AG.height(pop_band)
                        max_lat_ind = ceil((90 - min_lat) * pop_band_height / 180)
                        min_lat_ind = min(ceil((90 - max_lat) * pop_band_height / 180), max_lat_ind - 1)
                        min_lon_ind = ceil((min_lon + 180) * pop_band_width / 360)
                        max_lon_ind = max(ceil((max_lon + 180) * pop_band_width / 360), min_lon_ind + 1)
                        rows = UnitRange{Int}(min_lat_ind, max_lat_ind)
                        cols = UnitRange{Int}(min_lon_ind, max_lon_ind)
                        bounding_box_contents = AG.read(pop_band, rows, cols)
                        bounding_box_contents = [i > 0 ? i : 0 for i in bounding_box_contents] # Have to clean up negative values

                        # For converting indices back to lat/long coordinates
                        box_height, box_width = size(bounding_box_contents)
                        function box_to_coords(index)
                            x = div(index, box_width)
                            y = index % box_width
                            lat = min_lat + (max_lat - min_lat)/box_height*x
                            lon = min_lon + (max_lon - min_lon)/box_width*y
                            return (lat,lon)
                        end

                        # Convert indices into a set of values for an Empirical CDF
                        indices = collect(Iterators.flatten(1:length(bounding_box_contents)))

                        # Convert population density into a set of weights for an Empirical CDF
                        population_density = collect(Iterators.flatten(bounding_box_contents))
                        population_density /= sum(population_density)
                        weights = FrequencyWeights(population_density)

                        # For ICE or non-CNFL, run a weighted sampling, to obtain the coordinates to sample NSRDB from
                        # For CNFL, the coverage area is too small for this, so we just iterate through and choose spots
                        cnfl_ind = 1
                        # Obtain sample PV output for each location
                        coords = []
                        while length(coords) < num_samples
                            if (isassigned(cnfl, 1) && cnfl[1])
                                if cnfl_ind > length(indices)
                                    break
                                end
                                possible_sample = indices[cnfl_ind]
                                cnfl_ind = cnfl_ind + 1
                            else
                                possible_sample = sample(indices, weights)
                            end
                            possible_coords = box_to_coords(possible_sample)

                            # Determine whether these coordinates have been already added, or are part of excluded parts of CR
                            if !in(possible_coords, coords)
                                can_add = true
                                ag_coords = AG.createpoint(possible_coords[2],possible_coords[1])

                                # Add a conditional check for whether the location is within CNFL service area or not
                                # When we are constructing the CNFL dataset, this only adds a point if it's within a CNFL geom
                                # When we are constructing the ICE dataset, this only adds a point that's NOT within any
                                # Only do this when cnfl is defined: otherwise, assume we want national data
                                if isassigned(cnfl, 1)
                                    can_add = !cnfl[1]
                                    num_features = AG.nfeature(cnfl_gis)
                                    for i in 1:(num_features)
                                        ArchGDAL.getfeature(cnfl_gis, i - 1) do feature
                                            geom = AG.getgeomfield(feature, 0)
                                            source = AG.getspatialref(geom)
                                            AG.createcoordtrans(source, target) do transform
                                                AG.transform!(geom, transform)
                                                if AG.contains(geom, ag_coords)
                                                    can_add = cnfl[1]
                                                    println(string(string(possible_coords[1]),", ", string(possible_coords[2]), " is within a CNFL area"))
                                                end
                                            end
                                        end
                                    end
                                    if !can_add
                                        continue
                                    end
                                end
                                
                                num_features = AG.nfeature(area_protegidas_gis)
                                for i in 1:(num_features)
                                    ArchGDAL.getfeature(area_protegidas_gis, i - 1) do feature
                                        geom = AG.getgeomfield(feature, 0)
                                        source = AG.getspatialref(geom)
                                        AG.createcoordtrans(source, target) do transform
                                            AG.transform!(geom, transform)
                                            if AG.contains(geom, ag_coords)
                                                println(string("but ", string(possible_coords[1]), ", ", string(possible_coords[2]), " is within a protected area so we can't use it"))
                                                can_add = false # Not using this point because it is in an uninhabited location
                                            end
                                        end
                                    end
                                end
                                
                                if !can_add
                                    continue
                                end
                                
                                pv_output = -1
                                try
                                    lat, lon = possible_coords
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
    
    return pv_outputs_array
    
end

function get_nsrdb_sam_pv_output(;lat=9.817934, lon=-84.070552, tz=-6, year=2010, pipeline=true)
    if pipeline == true
        nsrdb_sam_df = get_nsrdb_sam_df(lat, lon, tz, year)
        pv_output = values(nsrdb_sam_df["Generation"])
    else
        pv_output=readdlm("data/pv_output.txt", '\t', Float64, '\n')
    end
    return pv_output
end
    
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

####################

# This function is completely unnecessary right now, I'm just keeping it here as reference in case it's useful in the future
@pyimport pypvwatts;
function predict_solar_output_at_location(lat=9.817934,lon=-84.070552)
    PVWatts = pypvwatts.PVWatts
    # Get api key
    credential_file = open("nrel-credentials.txt")
    nrel_credentials = readlines(credential_file)
        # You must have an NSRDB api key
    api_key = nrel_credentials[4]
    close(credential_file)
    
    
    PVWatts.api_key = api_key
    result = PVWatts.request(
        system_capacity=4, module_type=1, array_type=1,
        azimuth=190, tilt=30, dataset="tmy2",
        losses=13, lat=lat, lon=lon)
    println(result.ac_annual)
end