#!/usr/bin/env python
#from ecmwfapi import ECMWFDataServer
import cdsapi

#server = ECMWFDataServer(url="https://api.ecmwf.int/v1",
#                         key="2a8eba4d90b6fe70777cbbcbf2469b9b",
#                         email="bo.huang@noaa.gov")

#c = cdsapi.Client(url="https://ads.atmosphere.copernicus.eu/api/v2", key="2a8eba4d90b6fe70777cbbcbf2469b9b")
c = cdsapi.Client(url="https://ads.atmosphere.copernicus.eu/api/v2", key="8252:ed7cb229-e3e2-40d8-8fc6-2656806a3d29")
#c = cdsapi.Client(url=https://ads.atmosphere.copernicus.eu/api/v2, key=8252:ed7cb229-e3e2-40d8-8fc6-2656806a3d29)

c.retrieve(
    'cams-global-atmospheric-composition-forecasts',
    {
        'date': '2022-09-08',
        'format': 'netcdf',
        'variable': [
            'total_aerosol_optical_depth_469nm',
            'total_aerosol_optical_depth_550nm',
            'total_aerosol_optical_depth_670nm',
            'total_aerosol_optical_depth_865nm',
            'total_aerosol_optical_depth_1240nm',
        ],
        'leadtime_hour': '0',
        'time': [
            '00:00',
        ],
        'type':'analysis',
        'area': [
            90, 0, -90, 360,
	],
    },
    'cams_aods_2022090800.nc')
#            '00:00', '06:00', '12:00', '18:00',
exit()
