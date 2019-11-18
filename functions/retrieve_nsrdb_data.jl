using PyCall
using PyPlot
using DelimitedFiles
using ArchGDAL
using StatsBase

function monte_carlo_solar_output(;num_samples=100)
    pop_density_filename = "data/gpw-v4-population-density-rev11_2020_2pt5_min_tif/gpw_v4_population_density_rev11_2020_2pt5_min.tif"
    monte_carlo_coords = Array{Tuple{Float64, Float64}}(undef, 0)

    ArchGDAL.registerdrivers() do
        ArchGDAL.read(pop_density_filename) do dataset

            # Get the band of data corresponding to population density per ~5km square of the Earth's surface
            band = ArchGDAL.getband(dataset, 1)

            # Limit to a bounding box surrounding Costa Rica (excluding Cocos Island National Park)
            min_lat = 8.040682
            max_lat = 11.2195684
            min_lon = -85.956896
            max_lon = -82.5060208
            band_width = ArchGDAL.width(band)
            band_height = ArchGDAL.height(band)   
            max_lat_ind = ceil((90 - min_lat) * band_height / 180)
            min_lat_ind = min(ceil((90 - max_lat) * band_height / 180), max_lat_ind - 1)
            min_lon_ind = ceil((min_lon + 180) * band_width / 360)
            max_lon_ind = max(ceil((max_lon + 180) * band_width / 360), min_lon_ind + 1)
            rows = UnitRange{Int}(min_lat_ind, max_lat_ind)
            cols = UnitRange{Int}(min_lon_ind, max_lon_ind)
            bounding_box_contents = ArchGDAL.read(band, rows, cols)
            bounding_box_contents = [i > 0 ? i : 0 for i in bounding_box_contents] # Have to clean up negative values

            # Convert indices into a set of values for an Empirical CDF
            indices = collect(Iterators.flatten(1:length(bounding_box_contents)))

            # Convert population density into a set of weights for an Empirical CDF
            population_density = collect(Iterators.flatten(bounding_box_contents))
            population_density /= sum(population_density)
            weights = Weights(population_density)

            # Run the weighted sampling, to obtain the coordinates we will sample NSRDB from
            samples = sample(indices, weights, num_samples, replace=false)

            # For converting indices back to lat/long coordinates
            box_height, box_width = size(bounding_box_contents)
            function box_to_coords(index)
                x = div(index, box_width)
                y = index % box_width
                lat = min_lat + (max_lat - min_lat)/box_height*x
                lon = min_lon + (max_lon - min_lon)/box_width*y
                return (lat,lon)
            end

            for sample in samples
                push!(monte_carlo_coords, box_to_coords(sample));
            end
        end
    end
    
    # Obtain sample PV output for each location
    cumulative_pv_output = Array{Float64,1}(undef,0)
    for (lat, lon) in monte_carlo_coords
        sleep(5)
        pv_output = convert(Array{Float64,1},get_nsrdb_sam_pv_output(lat=lat, lon=lon))
        if length(cumulative_pv_output) == 0
            append!(cumulative_pv_output, pv_output)
        else
            cumulative_pv_output += pv_output
        end
    end
    
    # Average all of them, to return a normalized data set for a hypothetical "solar year"?
    return cumulative_pv_output ./ num_samples
    
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

    # The first two rows are not data values
    # The column names and the "first row" are metadata identifiers and values, respectively
    # The "second row" is what we'd consider the "column names" for the actual data, which is row 3 and beyond
    # read the actual data, "row" 3 and below
    # nsrdb_data_frame = read_csv(url, skiprows=2);
    # return nsrdb_data_frame;
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