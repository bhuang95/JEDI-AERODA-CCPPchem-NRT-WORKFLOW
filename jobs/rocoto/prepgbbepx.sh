#!/bin/ksh -x

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
export HOMEjedi=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
source ${HOMEjedi}/jedi_module_base.hera
module list
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"

status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
#configs="base"
#for config in $configs; do
#    . $EXPDIR/config.${config}
#    status=$?
#    [[ $status -ne 0 ]] && exit $status
#done
###############################################################
STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepgbbepx"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10

CDATE=${CDATE:-"2001010100"}
CASE=${CASE:-"C96"}
GBBDIR_NC=${GBBDIR_NC:-""}
GBBDIR_BIN=${GBBDIR_BIN:-""}
#GBBEPxDIR=${GBBEPxDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/GBBEPx/"}
GBBEPxDIR=${GBBEPxDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/GBBEPx/"}
CNVTEXEC=${CNVTEXEC:-${HOMEgfs}/exec/convert_gbbepx.x}

RES=`echo $CASE | cut -c2-4`
YY=`echo "${CDATE}" | cut -c1-4`
MM=`echo "${CDATE}" | cut -c5-6`
DD=`echo "${CDATE}" | cut -c7-8`
HH=`echo "${CDATE}" | cut -c9-10`

YMD=${YY}${MM}${DD}
TIMESTR="${YY}-${MM}-${DD} ${HH}:00:00.0"
GBBDIR_NC_YMD=${GBBDIR_NC}/${YMD}
mkdir -p ${GBBDIR_NC_YMD}

ln -sf ${CNVTEXEC} ./
export LD_LIBRARY_PATH="/home/Mariusz.Pagowski/MAPP_2018/libs/fortran-datetime/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

tile=1
while [[ $tile -le 6 ]]
do 
    pathlon=${GBBEPxDIR}/${CASE}_fix/lon/lon_tile${tile}.dat
    pathlat=${GBBEPxDIR}/${CASE}_fix/lat/lat_tile${tile}.dat

#    pathebc=${GBBDIR_BIN}/GBBEPx.emis_BC.003.${YMD}.FV3.${CASE}Grid.tile${tile}.bin
#    patheoc=${GBBDIR_BIN}/GBBEPx.emis_OC.003.${YMD}.FV3.${CASE}Grid.tile${tile}.bin
#    pathepm25=${GBBDIR_BIN}/GBBEPx.emis_PM2.5.003.${YMD}.FV3.${CASE}Grid.tile${tile}.bin
#    patheso2=${GBBDIR_BIN}/GBBEPx.emis_SO2.003.${YMD}.FV3.${CASE}Grid.tile${tile}.bin
#    patheco=${GBBDIR_BIN}/GBBEPx.emis_CO.003.${YMD}.FV3.${CASE}Grid.tile${tile}.bin
#    patheplume=${GBBDIR_BIN}/GBBEPx.FRP.003.${YMD}.FV3.${CASE}Grid.tile${tile}.bin
    
    pathebc=${GBBDIR_BIN}/GBBEPxemis-BC-${CASE}GT${tile}_v4r0_${YMD}.bin
    patheoc=${GBBDIR_BIN}/GBBEPxemis-OC-${CASE}GT${tile}_v4r0_${YMD}.bin
    pathepm25=${GBBDIR_BIN}/GBBEPxemis-PM25-${CASE}GT${tile}_v4r0_${YMD}.bin
    patheso2=${GBBDIR_BIN}/GBBEPxemis-SO2-${CASE}GT${tile}_v4r0_${YMD}.bin
    patheco=${GBBDIR_BIN}/GBBEPxemis-CO-${CASE}GT${tile}_v4r0_${YMD}.bin
    patheplume=${GBBDIR_BIN}/GBBEPxFRP-MeanFRP-${CASE}GT${tile}_v4r0_${YMD}.bin

    outfile=${GBBDIR_NC_YMD}/FIRE_GBBEPx_data.tile${tile}.nc

if [[ -e ${outfile} ]]; then
   echo "${outfile} already exists and skip conversion"
   err=0
else

cat > convert_gbbepx.nl <<EOF
&record_input
   title = "GBBEPx emissions"
   tile = $tile
   time = "$TIMESTR"
   nlon = $RES
   nlat = $RES
   outfile     = "$outfile"
   pathlon     = "$pathlon"
   pathlat     = "$pathlat"
   pathebc     = "$pathebc"
   patheoc     = "$patheoc"
   pathepm25   = "$pathepm25"
   patheso2    = "$patheso2"
   patheco     = "$patheco"
   patheplume  = "$patheplume"
/
EOF

    ${CNVTEXEC}
    err=$?
    if [[ $err -ne 0 ]]; then
        echo "prepgbbepx failed and exit at ${err}"
	exit ${err}
    fi
fi

    ((tile=tile+1))

done

if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi

sleep 60
echo $(date) EXITING $0 with return code $err >&2
exit $err

