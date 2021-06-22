#!/bin/bash
#SBATCH -A wrf-chem
#SBATCH -q debug
#SBATCH -t 05:00
##SBATCH -n 40
#SBATCH --nodes=4
#SBATCH -J calc_analysis
#SBATCH -o log.out

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
###############################################################
# Source relevant configs
#configs="base"
#for config in $configs; do
#    . $EXPDIR/config.${config}
#    status=$?
#    [[ $status -ne 0 ]] && exit $status
#done
###############################################################
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean"}
ROTDIR=${ROTDIR:-""}
CDATE=${CDATE:-"2021061600"}
CASE_ENKF=${CASE_ENKF:-"C96"}
CASE_ENKF_GDAS=${CASE_ENKF_GDAS:-"C96"}
FHR=${FHR:-"06"}
METDIR_WCOSS=${METDIR_WCOSS:-"/scratch1/BMC/chem-var/pagowski/junk_scp/wcoss/"}
METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/"}
CDUMP=${CDUMP:-"gdas"}
NMEM_AERO=${NMEM_AERO:-"20"}
NMEM_EFCSGRP=${NMEM_EFCSGRP:-"4"}
ENSGRP=${ENSGRP:-"00"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
ANAEXEC=${ANAEXEC:-"${HOMEgfs}/exec/calc_analysis.x"}
CHGRESEXEC_GAU=${CHGRESEXEC_GAU:-"${HOMEgfs}/exec/chgres_recenter_ncio.exe"}
ENSEND=$((NMEM_EFCSGRP * ENSGRP))
ENSBEG=$((ENSEND - NMEM_EFCSGRP + 1))

NLN='/bin/ln -sf'
NRM='/bin/rm -rf'
NMV='/bin/mv -rf'

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepensana.grp${ENSGRP}.$$"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10


CYY=`echo "${CDATE}" | cut -c1-4`
CMM=`echo "${CDATE}" | cut -c5-6`
CDD=`echo "${CDATE}" | cut -c7-8`
CHH=`echo "${CDATE}" | cut -c9-10`
CYMD=${CYY}${CMM}${CDD}

GDATE=$(${NDATE} ${FHR} ${CDATE})
GYY=`echo "${GDATE}" | cut -c1-4`
GMM=`echo "${GDATE}" | cut -c5-6`
GDD=`echo "${GDATE}" | cut -c7-8`
GHH=`echo "${GDATE}" | cut -c9-10`


if [ ${ENSGRP} -gt 0 ]; then            
    [[ ! ${DATA}/wcossdata_cut ]] && mkdir ${DATA}/wcossdata_cut
    [[ ! ${DATA}/wcossdata_ges ]] && mkdir ${DATA}/wcossdata_ges
    TARFILE_CUT=${METDIR_WCOSS}/enkf${CDUMP}.${CDATE}_grp.${ENSGRP}.tar
    TARFILE_GES=${METDIR_WCOSS}/enkf${CDUMP}.${GDATE}_grp.${ENSGRP}.tar
    tar -xvf ${TARFILE_CUT}  --directory ${DATA}/wcossdata_cut
    ERR1=$?
    tar -xvf ${TARFILE_GES}  --directory ${DATA}/wcossdata_ges
    ERR2=$?

    if [[ $ERR1 -ne 0 || $ERR2 -ne 0]]; then
        echo "Untar file failed and exit"
        exit 1
    fi

### Loop through members to recover ensemble analysis from background and increment files.
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

    for mem0 in {${ENSBEG}..${ENSEND}}; do
        mem1=$(printf "%03d" ${mem0})
	mem="mem${mem1}"
        ${NLN} wcossdata_cut/${mem}/gdas.t${CHH}z.ratminc.nc wcossdata_cut/${mem}/gdas.t${CHH}z.ratminc.nc.${FHR}
        ${NLN} wcossdata_ges/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc wcossdata_ges/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc.${FHR}

[[ -e calc_analysis.nml ]] && ${NRM} calc_analysis.nml
cat > calc_analysis.nml <<EOF
&setup
datapath = './'
analysis_filename = 'wcossdata_cut/${mem}/gdas.t${CHH}z.ratmanl.oriRe.nc'
firstguess_filename = 'gdas.tsdata_ges/${mem}/{GHH}z.atmf0${FHR}.nc'
increment_filename = 'wcossdata_cut/${mem}/gdas.t${CHH}z.ratminc.nc'
fhr = ${FHR}
use_nemsio_anl = .false.
/
EOF

ulimit -s unlimited
${NLN} ${ANAEXEC}  ./calc_analysis.x
srun -n 127 calc_analysis.x  calc_analysis.nml

ERR3=$?

        if [[ ${ERR3} -eq 0 ]]; then
            echo "calc_analysis.x runs successfully and rename the analysis file."
            ${NMV} wcossdata_cut/${mem}/gdas.t${CHH}z.ratmanl.oriRe.nc.${FHR} wcossdata_cut/${mem}/gdas.t${CHH}z.ratmanl.oriRe.${mem}.nc
            ${NRM} wcossdata_cut/${mem}/gdas.t${CHH}z.ratminc.nc.${FHR} wcossdata_cut/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc.${FHR}
        else
            echo "calc_analysis.x failed at member ${mem} and exit"
            exit 1
        fi
    done
else
    echo "ENSGRP need to be larger than zero to generate ensemble atmos analysis, and exit"
    exit 1
fi

### Convert gdas ensemble analysis to CASE resolution (L64) and reload modules
. $HOMEgfs/ush/load_fv3gfs16_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

${NLN} ${CHGRESEXEC_GAU} ./   

RES=`echo $CASE | cut -c2-4`
LONB=$((4*res))
LATB=$((2*res))

for mem0 in {${ENSBEG}..${ENSEND}}; do
    mem1=$(printf "%03d" ${mem0})
    mem="mem${mem1}"
    [[ -e fort.43 ]] && ${NRM} calc_analysis.nml
    [[ -e ref_file.nc ]] && ${NRM} ref_file.nc
    ${NLN} ${ROTDIR}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc ./ref_file.nc
cat > fort.43 <<EOF
 &chgres_setup
  i_output=$LONB
  j_output=$LATB
  input_file="wcossdata_cut/${mem}/gdas.t${CHH}z.ratmanl.oriRe.${mem}.nc"
  output_file="wcossdata_cut/${mem}/gdas.t${CHH}z.ratmanl.${mem}.nc"
  terrain_file="wcossdata_ges/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc"
  cld_amt=.F.
  ref_file="ref_file.nc"
/
EOF

mpirun -n 1 ./chgres_recenter_ncio.exe "./fort.43"
ERR4=$?

if [[ ${ERR4} -eq 0 ]]; then
   echo "chgres_recenter_ncio.exe runs successful for ${mem} and move data."
   OUTDIR=${METDIR_NRT}/${CASE}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   ${NMV} wcossdata_cut/${mem}/gdas.t${CHH}z.ratmanl.${mem}.nc ${OUTDIR}/gdas.t${CHH}z.ratmanl.nc
else
   echo "chgres_recenter_ncio.exe run failed for ${mem} and exit."
   exit 1
fi
done

if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi

### Convert sfcanl RESTART files to CASE resolution 
export APRUN='srun --export=ALL'
export CHGRESEXEC=${CHGRESEXEC:-"${HOMEgfs}/exec/chgres_recenter_ncio.exe"}
IFXORGO=${HOMEgfs}/fix/fix_fv3_gmted2010
export INPUT_TYPE=restart
export CRES=${CASE_ENKF}
export MOSAIC_FILE_INPUT_GRID=${FIXOROG}/${CASE_ENKF_GDAS}/${CASE_ENKF_GDAS}_mosaic.nc
export OROG_DIR_INPUT_GRID=${FIXOROG}/C${CASE_ENKF_GDAS}
export OROG_FILES_INPUT_GRID=${CASE_ENKF_GDAS}_oro_data.tile1.nc'","'${CASE_ENKF_GDAS}_oro_data.tile2.nc'","'${CASE_ENKF_GDAS}_oro_data.tile3.nc'","'${CASE_ENKF_GDAS}_oro_data.tile4.nc'","'${CASE_ENKF_GDAS}_oro_data.tile5.nc'","'${CASE_ENKF_GDAS}_oro_data.tile6.nc

export MOSAIC_FILE_INPUT_GRID=${FIXOROG}/${CASE_ENKF}/${CASE_ENKF}_mosaic.nc

export CONVERT_ATM=".false."
export CONVERT_SFC=".true."
export CONVERT_NST=".true."

CDATEM3=$(${NDATE} -3 ${CDATE})
CM3YY=`echo "${CDATEM3}" | cut -c1-4`
CM3MM=`echo "${CDATEM3}" | cut -c5-6`
CM3DD=`echo "${CDATEM3}" | cut -c7-8`
CM3HH=`echo "${CDATEM3}" | cut -c9-10`
CM3YMD=${CM3YY}${CM3MM}${CM3DD}
export SFC_FILES_INPUT=${CM3YMD}.${CM3HH}0000.sfcanl_data.tile1.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile2.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile3.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile4.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile5.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile6.nc

for mem0 in {${ENSBEG}..${ENSEND}}; do
    mem1=$(printf "%03d" ${mem0})
    mem="mem${mem1}"
    export COMIN=wcossdata_cut/${mem}/RESTART

${HOMEgfs}/ush/chgres_cube.sh
ERR5=$?
if [[ ${ERR5} -eq 0 ]]; then
   echo "chgres_cube runs successful for ${mem} and move data."

   OUTDIR=${METDIR_NRT}/${CASE}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/RESTART
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   for tile in tile1 tile2 tile3 tile4 tile5 tile6; do
       ${NMV} out.sfc.${tile}.nc ${OUTDIR}/${CYMD}.${CHH}0000.sfc_data.${tile}.nc 
   done
   ${NRM} fort.41
else
   echo "chgres_cube run  failed for ${mem} and exit."
   exit 1
fi
done

#if [[ ${ERR1} -eq 0 && ${ERR2} -eq 0 && ${ERR3} -eq 0 && ${ERR4} -eq 0 && ${ERR5} -eq 0 ]]; then
#   ${NRM} ${DATA}
#fi
err=$?
echo $(date) EXITING $0 with return code $err >&2
exit $err

