#!/bin/bash
#SBATCH -J hpss-fv3nrt-CNTLANL
#SBATCH -A wrf-chem 
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog//DA-CNTLANL.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog//DA-CNTLANL.out

#---------------------------------------------------------------------
# Driver script for running on Hera.
#
# Edit the 'config' file before running.
#---------------------------------------------------------------------

#set -x


NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

MONTHS="
202108
202109
202110
202111
202112
202201
202202
202203
202204
202205
202206
"

CURDIR=$(pwd)
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/NRT-GEFS-Aerosols/DA-CNTLANL-LATLON/
SRCDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/metPlusDiag/fv32pllData/global-workflow-CCPP2-Chem-NRT-clean/cntlAnal/

for MONTH in ${MONTHS}; do
    cd ${CURDIR}
    YEAR=${MONTH::-2}
    echo ${YEAR}
    echo ${MONTH}
    TMPDIR=${CURDIR}/${MONTH}
    mkdir -p ${TMPDIR}
    mv ${SRCDIR}/*${MONTH}*.nc ${TMPDIR}
    DETDIR=${HPSSDIR}/${YEAR}
    hsi "mkdir -p ${DETDIR}"
    cd ${TMPDIR}
    htar -cv -f ${DETDIR}/DA-CNTLANL-${MONTH}.tar *

    ERR=$?
    if [ ${ERR} != '0' ]; then
        echo "HTAR cntl failed at ${MONTH} and exit."
        exit ${ERR}
    else
        echo "HTAR cntl succeeded at ${MONTH}."
	echo ${MONTH} >> ${CURDIR}/record.complete
	rm -rf ${TMPDIR}
     fi

done

exit 0
