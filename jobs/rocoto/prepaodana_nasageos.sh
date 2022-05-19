#!/bin/bash --login 
##SBATCH -J NASA-AOD
##SBATCH -A chem-var
##SBATCH -p service
##SBATCH -n 1
##SBATCH -t 01:29:00
##SBATCH -o EC_AOD.out
##SBATCH -e EC_AOD.out
###! /usr/bin/env bash

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

touch ~/.urs_cookies

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodana_nasa"

[[ ! -d $DATA ]] && mkdir -p $DATA
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
CDATE=${CDATE:-"2022051500"}
CYCINTHR=${CYCINTHR:-"6"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
NASAANA_NRT=${NASAANA_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/reanalyses/NASA-anal/pll"}
INFILE="GEOS.fp.asm.tavg3_2d_aer_Nx"
GEOSHTTP="https://portal.nccs.nasa.gov/datashare/gmao/geos-fp/das"
SDATE=${CDATE}
EDATE=`${NDATE} 18 ${CDATE}`

[[ ! -d ${NASAANA_NRT} ]] && mkdir -p ${NASAANA_NRT}
cd $DATA || exit 10

while [[ ${SDATE} -le ${EDATE} ]]
do
    SDATE_M2=`${NDATE} -2 ${SDATE}`
    SDATE_P1=`${NDATE} +1 ${SDATE}`

    YY_S=`echo ${SDATE} | cut -c 1-4`
    MM_S=`echo ${SDATE} | cut -c 5-6`
    DD_S=`echo ${SDATE} | cut -c 7-8`
    HH_S=`echo ${SDATE} | cut -c 9-10`
    YY_M2=`echo ${SDATE_M2} | cut -c 1-4`
    MM_M2=`echo ${SDATE_M2} | cut -c 5-6`
    DD_M2=`echo ${SDATE_M2} | cut -c 7-8`
    HH_M2=`echo ${SDATE_M2} | cut -c 9-10`
    YY_P1=`echo ${SDATE_P1} | cut -c 1-4`
    MM_P1=`echo ${SDATE_P1} | cut -c 5-6`
    DD_P1=`echo ${SDATE_P1} | cut -c 7-8`
    HH_P1=`echo ${SDATE_P1} | cut -c 9-10`

### Download EC AOD analysis at ${CDATE}
    FILE_S=${INFILE}.${YY_S}${MM_S}${DD_S}_${HH_S}00.V01.nc4
    FILE_M2=${INFILE}.${YY_M2}${MM_M2}${DD_M2}_${HH_M2}30.V01.nc4
    FILE_P1=${INFILE}.${YY_P1}${MM_P1}${DD_P1}_${HH_P1}30.V01.nc4
    [[ -e files.txt ]] && rm -rf files.txt
    [[ -e file.nc ]] && rm -rf file.nc
    [[ -e ${FILE_S}.* ]] && rm -rf ${FILE_S}.*
    [[ -e ${FILE_M2}.* ]] && rm -rf ${FILE_M2}.*
    [[ -e ${FILE_P1}.* ]] && rm -rf ${FILE_P1}.*

#${GEOSHTTP}/Y${YY_S}/M${MM_S}/D${DD_S}/${FILE_S}
cat << EOF >> files.txt
${GEOSHTTP}/Y${YY_M2}/M${MM_M2}/D${DD_M2}/${FILE_M2}
${GEOSHTTP}/Y${YY_P1}/M${MM_P1}/D${DD_P1}/${FILE_P1}
EOF

wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --content-disposition -i files.txt

err=$?
if [ ${err} != '0' ]; then
    echo "Failed downloading NASA AOD analysis at ${SDATE} and exit!"
    exit 1
else
    echo "Downloading NASA AOD analysis  succeeded at ${SDATE} and proceed to next step!"
fi

### Calculate AOD at ${CDATE}
ncea -v TOTEXTTAU ${FILE_M2} ${FILE_P1} file.nc
ncrename -v TOTEXTTAU,AODANA file.nc

unit="minutes since ${YY_S}-${MM_S}-${DD_S} ${HH_S}:00:00"
ncatted -O -a units,time,m,c,"${unit}" file.nc
ncatted -O -a begin_date,time,m,i,${YY_S}${MM_S}${DD_S} file.nc
ncatted -O -a begin_time,time,m,i,${HH_S}0000 file.nc

OUTFILE=${NASAANA_NRT}/m2_aods_${SDATE}_ll.nc

err=$?
if [ ${err} != '0' ]; then
    echo "Failed ncks EC AOD analysis  at ${CDATE} and exit!"
    exit 1
else
    echo "NASA AOD analysis succeeded at ${CDATE} and exit!"
    rm -rf files.txt ${FILE_S} ${FILE_M2} ${FILE_P1} 
    mv file.nc ${OUTFILE}
fi

SDATE=`${NDATE} ${CYCINTHR} ${SDATE}`

done

if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
