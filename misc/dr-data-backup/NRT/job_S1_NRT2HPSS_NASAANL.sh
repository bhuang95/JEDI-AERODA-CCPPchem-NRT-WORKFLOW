#!/bin/bash
#SBATCH -J hpss-nasa-pll
#SBATCH -A wrf-chem 
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog//nasa_pll.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog//nasa_pll.out

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
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/NRT-GEFS-Aerosols/NASA-AOD-ANL/
SRCDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/reanalyses/NASA-anal/pll/

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
    htar -cv -f ${DETDIR}/NASA-PLL-${MONTH}.tar *

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
