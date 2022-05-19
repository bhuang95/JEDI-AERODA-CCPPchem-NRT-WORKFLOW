#!/bin/bash --login 
##SBATCH -J FV3-AOD
##SBATCH -A chem-var
##SBATCH -p batch
##SBATCH -q debug
##SBATCH -n 1
##SBATCH -t 00:29:00
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
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"

status=$?
[[ $status -ne 0 ]] && exit $status

#curdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/nrtDisplay/aodAna/
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
CDATE=${CDATE:-"2022051500"}
CYCINTHR=${CYCINTHR:-"6"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
EXPRUN=${EXPRUN:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns"}
EXPNAMES=${EXPNAMES:-"global-workflow-CCPP2-Chem-NRT-clean global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst"}
FV3EXE=${FV3EXE:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/fv3aod2ll.x"}
OUTDIR_NRT=${OUTDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/metPlusDiag/fv32pllData/"}
FIXDIR=${FIXDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski"}
GRID=${GRID:-"C96"}
SENSOR=${SENSOR:-"viirs-m_npp"}

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodana_fv3"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10

ln -sf ${FV3EXE} ./fv3aod2ll.x

SDATE=${CDATE}
EDATE=`${NDATE} 18  ${CDATE}`
while [[ ${SDATE} -le ${EDATE} ]]
do
    SDATE_M6=`${NDATE} -${CYCINTHR} ${SDATE}`

    YY_S=`echo ${SDATE} | cut -c 1-4`
    MM_S=`echo ${SDATE} | cut -c 5-6`
    DD_S=`echo ${SDATE} | cut -c 7-8`
    HH_S=`echo ${SDATE} | cut -c 9-10`
    YY_M6=`echo ${SDATE_M6} | cut -c 1-4`
    MM_M6=`echo ${SDATE_M6} | cut -c 5-6`
    DD_M6=`echo ${SDATE_M6} | cut -c 7-8`
    HH_M6=`echo ${SDATE_M6} | cut -c 9-10`

for EXPNAME in ${EXPNAMES}; do
    if [[ ${EXPNAME} == "global-workflow-CCPP2-Chem-NRT-clean" ]]; then
        FIELDS="cntlBckg cntlAnal"
    else
        FIELDS="cntlBckg"
    fi

    for FIELD in ${FIELDS}; do
        INDIR=${EXPRUN}/${EXPNAME}/dr-data-backup/gdas.${YY_M6}${MM_M6}${DD_M6}/${HH_M6}/RESTART/
        OUTDIR=${OUTDIR_NRT}/${EXPNAME}/${FIELD}/
	OUTFILE="fv3_aods_${SENSOR}_${YY_S}${MM_S}${DD_S}${HH_S}_ll.nc"

        [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}

	if [[ ${FIELD} == "cntlBckg" ]]; then
           NC="nc.ges"
	else
           NC="nc"
	fi

[[ -e fv3aod2ll.nl ]] && rm -rf fv3aod2ll.nl
cat > fv3aod2ll.nl <<EOF
&record_input
 date="${YY_S}${MM_S}${DD_S}${HH_S}"
 input_grid_dir="${FIXDIR}/fix_fv3/${GRID}"
 fname_grid="grid_spec.tile?.nc"
 input_fv3_dir="${INDIR}"
 fname_fv3="${YY_S}${MM_S}${DD_S}.${HH_S}0000.fv_aod_LUTs_v.${SENSOR}.res.tile?.${NC}"
/
&record_interp
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${OUTDIR}"
 fname_aod_ll="${OUTFILE}"
/
EOF

./fv3aod2ll.x

err=$?
if [ ${err} != '0' ]; then
    echo "FV3 processing failed at ${SDATE} for ${EXPNAME}-${FIELD} and failed!"
    exit 1
else
    echo "FV3 processing succeeded at ${SDATE} for ${EXPNAME}-${FIELD} and proceed to next step!"
fi

    done # FIELD
done  # EXPNAME

SDATE=`${NDATE} ${CYCINTHR} ${SDATE}`

done

if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
