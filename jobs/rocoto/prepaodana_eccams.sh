#!/bin/bash --login 
##SBATCH -J EC-AOD
##SBATCH -A chem-var
##SBATCH -p service
##SBATCH -n 1
##SBATCH -t 00:29:00
##SBATCH -o EC_AOD.out
##SBATCH -e EC_AOD.out
##! /usr/bin/env bash

###############################################################
## Abstract:
## Create biomass burning emissions for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################
# Source FV3GFS workflow modules
#. $HOMEgfs/ush/load_fv3gfs_modules.sh
#. /apps/lmod/lmod/init/bash
#module purge
#module load intel impi netcdf/4.6.1 nco # Modules required on NOAA Hera
set -x
export HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20210701/build/"}
. ${HOMEjedi}/jedi_module_base.hera
moudle load intel
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest
module load nco
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"

status=$?
[[ $status -ne 0 ]] && exit $status

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodana_ec"

[[ ! -d $DATA ]] && mkdir -p $DATA
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
CDATE=${CDATE:-"2022051500"}
CYCINTHR=${CYCINTHR:-"6"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
ECANA_NRT=${ECANA_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/reanalyses/EC-anal/pll"}
ECAPIPY=${ECAPIPY:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/extApps/miniconda3/bin/python3.9"}
OUTFILE=cams_aods

CYY=`echo ${CDATE} | cut -c 1-4`
CMM=`echo ${CDATE} | cut -c 5-6`
CDD=`echo ${CDATE} | cut -c 7-8`
CHH=`echo ${CDATE} | cut -c 9-10`
CYMD=`echo ${CDATE} | cut -c 1-8`

cd $DATA || exit 10

[[ ! -d ${ECANA_NRT} ]] && mkdir -p ${ECANA_NRT}
[[ -f ${OUTFILE}_${CYMD}.nc ]] && rm -rf ${OUTFILE}_${CYMD}.nc
[[ -f ${OUTFILE}_${CYMD}00.nc ]] && rm -rf ${OUTFILE}_${CYMD}00.nc
[[ -f ${OUTFILE}_${CYMD}06.nc ]] && rm -rf ${OUTFILE}_${CYMD}06.nc
[[ -f ${OUTFILE}_${CYMD}12.nc ]] && rm -rf ${OUTFILE}_${CYMD}12.nc
[[ -f ${OUTFILE}_${CYMD}18.nc ]] && rm -rf ${OUTFILE}_${CYMD}18.nc

### Download EC AOD analysis at ${CDATE}
#cp  ${DOWNLOADEXEC} download_ec_cams_ana.py
[[ -f download_ec_cams_ana.py ]] && rm -rf download_ec_cams_ana.py
cat << EOF >> download_ec_cams_ana.py
#!/usr/bin/env python
from datetime import datetime
from datetime import timedelta
from ecmwfapi import ECMWFDataServer
import cdsapi
import sys

server = ECMWFDataServer(url="https://api.ecmwf.int/v1",
                         key="2a8eba4d90b6fe70777cbbcbf2469b9b",
                         email="bo.huang@noaa.gov")

c = cdsapi.Client()

c.retrieve(
    'cams-global-atmospheric-composition-forecasts',
    {
        'date': '${CYY}-${CMM}-${CDD}',
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
            '00:00', '06:00', '12:00', '18:00',
        ],
        'type':'analysis',
        'area': [
	     90, -180, -90, 180,
        ],
    },
    'cams_aods_${CYMD}.nc')
exit()
EOF

${ECAPIPY} download_ec_cams_ana.py
err=$?
if [ ${err} != '0' ]; then
    echo "Failed downloading EC AOD analysis at ${CDATE} and exit!"
    exit 1
else
    echo "Downloading EC AOD analysis  succeeded at ${CDATE} and proceed to next step!"
fi

### nck files at 00, 06, 12, 18
ncks -d time,0,0 ${OUTFILE}_${CYMD}.nc ${OUTFILE}_${CYMD}00.nc
ncks -d time,1,1 ${OUTFILE}_${CYMD}.nc ${OUTFILE}_${CYMD}06.nc
ncks -d time,2,2 ${OUTFILE}_${CYMD}.nc ${OUTFILE}_${CYMD}12.nc
ncks -d time,3,3 ${OUTFILE}_${CYMD}.nc ${OUTFILE}_${CYMD}18.nc

err=$?
if [ ${err} != '0' ]; then
    echo "Failed ncks EC AOD analysis  at ${CDATE} and exit!"
    exit 1
else
    echo "ncks EC AOD analysis  succeeded at ${CDATE} and exit!"
    mv ${OUTFILE}_${CYMD}??.nc ${ECANA_NRT}/
fi
    
if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
