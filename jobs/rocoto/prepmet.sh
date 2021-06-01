#!/bin/ksh -x

###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base prepmet"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

###############################################################
# Source machine runtime environment
. $BASE_ENV/${machine}.env prep
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Set script and dependency variables
export OPREFIX="${CDUMP}.t${cyc}z."
export COMOUT="$ROTDIR/$CDUMP.$PDY/$cyc"
[[ ! -d $COMOUT ]] && mkdir -p $COMOUT

###############################################################
# Execute the JJOB
$HOMEgfs/jobs/JAERO_PREPMET
status=$?
exit $status

