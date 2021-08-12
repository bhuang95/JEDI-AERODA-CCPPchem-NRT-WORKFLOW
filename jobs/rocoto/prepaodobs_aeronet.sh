#!/bin/bash --login 
##SBATCH --account=chem-var
##SBATCH --qos=debug
##SBATCH --ntasks=40
##SBATCH --cpus-per-task=10
##SBATCH --time=5
##SBATCH --job-name="bashtest"
##SBATCH --exclusive
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
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"

status=$?
[[ $status -ne 0 ]] && exit $status

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodobs_aeronet"

[[ ! -d $DATA ]] && mkdir -p $DATA
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
OBSDIR_AERONET_NRT=${OBSDIR_MODIS_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/aodObs"}
AODTYPE=${AODTYPE:-"AERONET"}
CDATE=${CDATE:-"2021072000"}
CYCINTHR=${CYCINTHR:-"6"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
AODOUTDIR=${OBSDIR_AERONET_NRT}/${AODTYPE}/${CDATE}/
AERONETEXEC=${HOMEgfs}/ush/JEDI/aeronet_aod2ioda.py
IODAUPGRADE=${HOMEjedi}/bin/ioda-upgrade.x 
OUTFILE_V1=AERONET_AOD.${CDATE}.v1.nc
OUTFILE_V2=AERONET_AOD.${CDATE}.nc

cd $DATA || exit 10

[[ ! -d ${AODOUTDIR} ]] && mkdir -p ${AODOUTDIR}
python ${AERONETEXEC} -t ${CDATE} -w ${CYCINTHR} -o ${OUTFILE_V1}
err=$?
if [ ${err} != '0' ]; then
    echo "aeronet.py failed at ${CDATE} and exit!"
    exit 1
else
    echo "aeronet.py succeeded at ${CDATE} and proceed to next step!"
fi

${IODAUPGRADE} ${OUTFILE_V1} ${OUTFILE_V2}
err=$?
if [ ${err} != '0' ]; then
    echo "ioda-upgrade.x failed at ${CDATE} and exit!"
    exit 1
else
    echo "ioda-upgrade.x succeeded at ${CDATE} and move data!"
    #/bin/mv ${OUTFILE_V1} ${AODOUTDIR}
    /bin/mv ${OUTFILE_V2} ${AODOUTDIR}
fi
    
if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
