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
MISSING_EC=${MISSING_EC:-"NO"}
RECORD_MISSING_EC=${RECORD_MISSING_EC:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.missingECAOD"}
SDATE=${CDATE}
EDATE=`${NDATE} 18 ${CDATE}`
OUTFILE=cams_aods

if [[ ${MISSING_EC} == "YES" ]]; then
    echo "EC AOD file missing and exit!"
    echo ${CDATE} >> ${RECORD_MISSING_EC} 
    exit 0
fi

[[ ! -d ${ECANA_NRT} ]] && mkdir -p ${ECANA_NRT}
cd $DATA || exit 10

while [[ ${SDATE} -le ${EDATE} ]]; do
   YY=`echo ${SDATE} | cut -c 1-4`
   MM=`echo ${SDATE} | cut -c 5-6`
   DD=`echo ${SDATE} | cut -c 7-8`
   HH=`echo ${SDATE} | cut -c 9-10`
   YMD=`echo ${SDATE} | cut -c 1-8`

   [[ -f ${OUTFILE}_${SDATE}.nc ]] && rm -rf ${OUTFILE}_${SDATE}.nc

### Download EC AOD analysis at ${CDATE}
#cp  ${DOWNLOADEXEC} download_ec_cams_ana.py
[[ -f download_ec_cams_ana.py ]] && rm -rf download_ec_cams_ana.py

cat << EOF >> download_ec_cams_ana.py
#!/usr/bin/env python
import cdsapi

c = cdsapi.Client(url="https://ads.atmosphere.copernicus.eu/api/v2", key="8252:ed7cb229-e3e2-40d8-8fc6-2656806a3d29")

c.retrieve(
    'cams-global-atmospheric-composition-forecasts',
    {
        'date': '${YY}-${MM}-${DD}',
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
            '${HH}:00',
        ],
        'type':'analysis',
    },
    'cams_aods_${SDATE}.nc')
exit()
EOF

#        'area': [
#	     90, -180, -90, 180,
#        ],

${ECAPIPY} download_ec_cams_ana.py
err=$?
if [[ ${err} != '0' ]]; then
    echo "Failed downloading EC AOD analysis at ${SDATE} and try again!"
    exit ${err}

else
    echo "Downloading EC AOD analysis  succeeded at ${SDATE} and proceed to next step!"
    mv ${OUTFILE}_${SDATE}.nc ${ECANA_NRT}/
fi

SDATE=`${NDATE} ${CYCINTHR} ${SDATE}`
done


if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
