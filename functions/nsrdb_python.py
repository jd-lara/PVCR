# needed to import a local module for SAM simulation off personal machine (requires installation at that location)
import site
import pandas as pd
import geopandas as gp
import numpy as np
import time
# Use site.addsitedir() to set the path to the SAM SDK API. Set path to the python directory.
site.addsitedir("/Applications/sam-sdk-2015-6-30-r3/languages/python/")

from PySAM.PySSC import PySSC

# The function which calls to NSRDB and uses the PySAM module
def call_nsrdb_and_ssc(request_url,lat=9.817934,lon=-84.070552,timezone=-6,elevation=746):
    # Get raw solar radiation data from NSRDB
    # (has a sleep to resolve issues of timeouts/overlapping queries/hitting hourly limits)
    time.sleep(2)
    df = pd.read_csv(request_url, skiprows=2)
    
    # Resource inputs for SAM model:
    ssc = PySSC()
    wfd = ssc.data_create()
    ssc.data_set_number(wfd, b'lat', lat)
    ssc.data_set_number(wfd, b'lon', lon)
    ssc.data_set_number(wfd, b'tz', timezone)
    ssc.data_set_number(wfd, b'elev', elevation)
    ssc.data_set_array(wfd, b'year', df["Year"])
    ssc.data_set_array(wfd, b'month', df["Month"])
    ssc.data_set_array(wfd, b'day', df["Day"])
    ssc.data_set_array(wfd, b'hour', df["Hour"])
    ssc.data_set_array(wfd, b'minute', df["Minute"])
    ssc.data_set_array(wfd, b'dn', df["DNI"])
    ssc.data_set_array(wfd, b'df', df["DHI"])
    ssc.data_set_array(wfd, b'wspd', df["Wind Speed"])
    ssc.data_set_array(wfd, b'tdry', df["Temperature"])
    
    # Create SAM compliant object  
    dat = ssc.data_create()
    ssc.data_set_table(dat, b'solar_resource_data', wfd)

    # Specify the system Configuration
    # Set system capacity in MW
    system_capacity = 1
    ssc.data_set_number(dat, b'system_capacity', system_capacity)
    # Set DC/AC ratio (or power ratio).
    # See https://sam.nrel.gov/sites/default/files/content/virtual_conf_july_2013/07-sam-virtual-conference-2013-woodcock.pdf
    ssc.data_set_number(dat, b'dc_ac_ratio', 1.1)
    # Set tilt of system in degrees
    ssc.data_set_number(dat, b'tilt', 8.5)
    # Set azimuth angle (in degrees) from north (0 degrees)
    ssc.data_set_number(dat, b'azimuth', 180)
    # Set the inverter efficency
    ssc.data_set_number(dat, b'inv_eff', 96)
    # Set the system losses, in percent
    ssc.data_set_number(dat, b'losses', 14.0757)
    # Specify fixed tilt system (0=Fixed, 1=Fixed Roof, 2=1 Axis Tracker, 3=Backtracted, 4=2 Axis Tracker)
    ssc.data_set_number(dat, b'array_type', 0)
    # Set ground coverage ratio
    ssc.data_set_number(dat, b'gcr', 0.4)
    # Set constant loss adjustment
    ssc.data_set_number(dat, b'adjust:constant', 0)
    # Set use of lifetime output to false
    ssc.data_set_number(dat, b'system_use_lifetime_output', 0)
    
    # Execute the PvWattsV5 module with this data
    mod = ssc.module_create(b'pvwattsv5');
    ssc.module_exec(mod, dat)
    
    # Obtain and return the “Generation” column of the result
    df["Generation"] = ssc.data_get_array(dat, b'gen')
    return df;

# A function to plot the coordinates corresponding to the PV outputs, upon a map of Costa Rica
def plot_mc_coords(coords_filename, cnfl=False):
    if cnfl:
        fp = "data/area_CNFL"
    else:
        fp = "data/CRI_adm/CRI_adm0.shp"
    data = gp.GeoDataFrame.from_file(fp)
    data = data.to_crs({'proj' :'longlat'})
    ax = data.plot()

    coords = np.loadtxt(coords_filename)
    coords_df = pd.DataFrame({'Latitude': [x[0] for x in coords], 'Longitude': [x[1] for x in coords]})
    coords_gdf = gp.GeoDataFrame(coords_df, geometry=gp.points_from_xy(coords_df.Longitude, coords_df.Latitude))
    coords_gdf.plot(ax=ax, color='red')
