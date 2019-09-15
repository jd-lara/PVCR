import pandas as pd
import numpy as np
from pprint import pprint

def call_ssc_with_dataframe(df,lat=9.817934,lon=-84.070552,timezone=1,elevation=0):

    #import additional module for SAM simulation:
    import site
    # Use site.addsitedir() to set the path to the SAM SDK API. Set path to the python directory.
    site.addsitedir("/Applications/sam-sdk-2015-6-30-r3/languages/python/")

    from PySAM.PySSC import PySSC

    # Resource inputs for SAM model:
    ssc = PySSC()
    wfd = ssc.data_create()
    ssc.data_set_number(wfd, b"lat", lat)
    ssc.data_set_number(wfd, b"lon", lon)
    ssc.data_set_number(wfd, b"tz", timezone)
    ssc.data_set_number(wfd, b"elev", elevation)
    ssc.data_set_array(wfd, b"year", df["Year"])
    ssc.data_set_array(wfd, b"month", df["Month"])
    ssc.data_set_array(wfd, b"day", df["Day"])
    ssc.data_set_array(wfd, b"hour", df["Hour"])
    ssc.data_set_array(wfd, b"minute", df["Minute"])
    ssc.data_set_array(wfd, b"dn", df["DNI"])
    ssc.data_set_array(wfd, b"df", df["DHI"])
    ssc.data_set_array(wfd, b"wspd", df["Wind Speed"])
    ssc.data_set_array(wfd, b"tdry", df["Temperature"])

    # Create SAM compliant object  
    dat = ssc.data_create()
    ssc.data_set_table(dat, b"solar_resource_data", wfd)
    ssc.data_free(wfd)

    # Specify the system Configuration
    # Set system capacity in MW
    system_capacity = 1
    ssc.data_set_number(dat, b"system_capacity", system_capacity)
    # Set DC/AC ratio (or power ratio). See https://sam.nrel.gov/sites/default/files/content/virtual_conf_july_2013/07-sam-virtual-conference-2013-woodcock.pdf
    ssc.data_set_number(dat, b"dc_ac_ratio", 1.1)
    # Set tilt of system in degrees
    ssc.data_set_number(dat, b"tilt", 25)
    # Set azimuth angle (in degrees) from north (0 degrees)
    ssc.data_set_number(dat, b"azimuth", 180)
    # Set the inverter efficency
    ssc.data_set_number(dat, b"inv_eff", 96)
    # Set the system losses, in percent
    ssc.data_set_number(dat, b"losses", 14.0757)
    # Specify fixed tilt system (0=Fixed, 1=Fixed Roof, 2=1 Axis Tracker, 3=Backtracted, 4=2 Axis Tracker)
    ssc.data_set_number(dat, b"array_type", 0)
    # Set ground coverage ratio
    ssc.data_set_number(dat, b"gcr", 0.4)
    # Set constant loss adjustment
    ssc.data_set_number(dat, b"adjust:constant", 0)
    
    ssc.data_set_number(dat, b"system_use_lifetime_output", 0)
    
    import PySAM.Pvwattsv5
    
    # execute and put generation results back into dataframe
    mod = PySAM.Pvwattsv5.wrap(dat)
    ssc.system_use_lifetime_output = 0
    mod.execute()
    pvwatts_output = mod.__getattribute__("Outputs")
    
    return pvwatts_output
#     pprint(pvwatts_output.dc)
#     print(len(pvwatts_output.dc))
#     ssc.module_exec(mod, dat)
#     df["generation"] = pvwatts_output# ssc.data_get_array(dat, b"gen")


#     ssc.module_free(mod)