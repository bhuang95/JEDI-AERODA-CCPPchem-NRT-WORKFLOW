#!/bin/ksh -x 
###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Execute the JJOB
export CASE=${CASE_CNTL:-"C96"}
$HOMEgfs/jobs/JGLOBAL_FORECAST
status=$?
exit $status
