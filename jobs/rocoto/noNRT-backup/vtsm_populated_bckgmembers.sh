#!/bin/ksh -x
###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base anal"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done


# Source machine runtime environment
. $BASE_ENV/${machine}.env anal 
status=$?
[[ $status -ne 0 ]] && exit $status

### Config ensemble hxaod calculation
export ENSBEG=1
export ENSEND=${NMEM_AERO}
###############################################################
#  Set environment.
export VERBOSE=${VERBOSE:-"YES"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi

#  Directories.
pwd=$(pwd)
export NWPROD=${NWPROD:-$pwd}
export HOMEgfs=${HOMEgfs:-$NWPROD}
export JEDIUSH=${JEDIUSH:-$HOMEgfs/ush/JEDI/}
export DATA=${DATA:-${DATAROOT}/vtsm.$$}

# Base variables
CDATE=${CDATE:-"2001010100"}
CDATEp6=$($NDATE $assim_freq $CDATE)
CDATEm3=$($NDATE -$vtsm_interval $CDATEp6)
CDATEp3=$($NDATE $vtsm_interval $CDATEp6)
CDUMP=${CDUMP:-"gdas"}
GDUMP=${GDUMP:-"gdas"}

CYY=$(echo $CDATE | cut -c1-4)
CMM=$(echo $CDATE | cut -c5-6)
CDD=$(echo $CDATE | cut -c7-8)
CHH=$(echo $CDATE | cut -c9-10)

CYYp6=$(echo $CDATEp6 | cut -c1-4)
CMMp6=$(echo $CDATEp6 | cut -c5-6)
CDDp6=$(echo $CDATEp6 | cut -c7-8)
CHHp6=$(echo $CDATEp6 | cut -c9-10)
datestrp6=${CYYp6}${CMMp6}${CDDp6}.${CHHp6}0000

CYYm3=$(echo $CDATEm3 | cut -c1-4)
CMMm3=$(echo $CDATEm3 | cut -c5-6)
CDDm3=$(echo $CDATEm3 | cut -c7-8)
CHHm3=$(echo $CDATEm3 | cut -c9-10)
datestrm3=${CYYm3}${CMMm3}${CDDm3}.${CHHm3}0000

CYYp3=$(echo $CDATEp3 | cut -c1-4)
CMMp3=$(echo $CDATEp3 | cut -c5-6)
CDDp3=$(echo $CDATEp3 | cut -c7-8)
CHHp3=$(echo $CDATEp3 | cut -c9-10)
datestrp3=${CYYp3}${CMMp3}${CDDp3}.${CHHp3}0000

ensmdir=${ROTDIR}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}
filetypes="fv_core.res fv_tracer.res  fv_srf_wnd.res  phy_data sfc_data"

# Utilities
export NCP=${NCP:-"/bin/cp"}
export NMV=${NMV:-"/bin/mv"}
export NLN=${NLN:-"/bin/ln -sf"}
export ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}

# other variables
ntiles=${ntiles:-6}

export DATA=${DATA}

mkdir -p $DATA && cd $DATA/

###############################################################
# need to loop through ensemble members if necessary
if [ $VTSM == "TRUE" ]; then
if [ $NMEM_AERO -gt 0 ]; then
  for mem0 in {1..$NMEM_AERO}; do
      mem0m3=$(expr ${mem0} + ${NMEM_AERO}) 
      mem0p3=$(expr ${mem0} + ${NMEM_AERO} + ${NMEM_AERO}) 
      memstr=mem`printf %03d $mem0`  
      memstrm3=mem`printf %03d $mem0m3`  
      memstrp3=mem`printf %03d $mem0p3`  
      memdir=${ensmdir}/${memstr}/RESTART
      memdirm3=${ensmdir}/${memstrm3}/RESTART
      memdirp3=${ensmdir}/${memstrp3}/RESTART
      mkdir -p ${memdirm3}
      mkdir -p ${memdirp3}
      cpfile=${datestrp6}.coupler.res.ges	
      cpfilem3=${datestrm3}.coupler.res.ges	
      cpfilep3=${datestrp3}.coupler.res.ges	
      ${NMV} ${memdir}/${cpfilem3} ${memdirm3}/${cpfilem3}_orig 
      ${NMV} ${memdir}/${cpfilep3} ${memdirp3}/${cpfilep3}_orig 
      ${NCP} ${memdir}/${cpfile} ${memdirm3}/
      ${NCP} ${memdir}/${cpfile} ${memdirp3}/

      cpfile=${datestrp6}.fv_core.res.nc.ges	
      cpfilem3=${datestrm3}.fv_core.res.nc.ges	
      cpfilep3=${datestrp3}.fv_core.res.nc.ges	
      ${NMV} ${memdir}/${cpfilem3} ${memdirm3}/${cpfilem3}_orig 
      ${NMV} ${memdir}/${cpfilep3} ${memdirp3}/${cpfilep3}_orig 
      ${NCP} ${memdir}/${cpfile} ${memdirm3}/
      ${NCP} ${memdir}/${cpfile} ${memdirp3}/

    # need to generate files for each tile 1-6
      for vtsmfile in ${filetypes}; do
          for n in $(seq 1 6); do
	      memfile=${datestrp6}.${vtsmfile}.tile${n}.nc.ges
	      memfilem3=${datestrm3}.${vtsmfile}.tile${n}.nc.ges
	      memfilep3=${datestrp3}.${vtsmfile}.tile${n}.nc.ges
	      ${NMV} ${memdir}/${memfilem3} ${memdirm3}/${memfile}
	      ${NMV} ${memdir}/${memfilep3} ${memdirp3}/${memfile}
	      err=$?
          done
      done
  done
        
  if  [ $err -ne 0 ]; then
    	    echo "VTSM  run failed and exit the program!!!"
    	    exit $err
  fi
fi
fi

###############################################################
# Postprocessing
cd $pwd
[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
