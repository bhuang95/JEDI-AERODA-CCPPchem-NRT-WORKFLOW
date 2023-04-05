#!/bin/bash
#SBATCH -J paper2hpss_nrtnoda
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 23:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/paper2hpss_nrtnoda.txt
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/psper2hpss_nrtnoda.txt

module load hpss
set -x

SDATE=2021091700
EDATE=2022063000
CINC=24
EXPNAME=global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst
FIELDS="gdas"
HERADIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/expRuns/
HERADATADIR=${HERADIR}/${EXPNAME}/dr-data-backup
HPSSDATADIR=${HPSSDIR}/${EXPNAME}/dr-data-backup-obsOnly
TMPDATADIR=${HERADATADIR}/tmp-mv2hpss
FAILEDREC=${HERADATADIR}/tmp-mv2hpss/Record.Failed
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

[[ ! -d ${TMPDATADIR} ]] && mkdir -p ${TMPDATADIR}

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}

    HPSSFILEDIR=${HPSSDATADIR}/${CY}/${CY}${CM}/

echo "hsi "mkdir -p ${HPSSFILEDIR}""
hsi "mkdir -p ${HPSSFILEDIR}"
ERR=$?
if [ ${ERR} != 0 ]; then
    echo ${CDATE}  >> ${FAILEDREC}
    exit 100
fi
 
    for FIELD in ${FIELDS}; do
        HERAFILEDIR=${HERADATADIR}/${FIELD}.${CY}${CM}${CD}
        HPSSFILE=${FIELD}.${CY}${CM}${CD}.tar 
        cd ${HERAFILEDIR}
        #htar -P -cvf ${HPSSFILE} *
	tar -cvf ${TMPDATADIR}/${HPSSFILE} *
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo ${CDATE}  >> ${FAILEDREC}
	    exit 100
        fi
	hsi "put ${TMPDATADIR}/${HPSSFILE} : ${HPSSFILEDIR}/${HPSSFILE}"
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo ${CDATE}  >> ${FAILEDREC}
	    exit 100
        else
	    echo "-------${CDATE} ${FIELD} completed and move on-------"
	    rm -rf ${HERAFILEDIR}
	    rm -rf ${TMPDATADIR}/${HPSSFILE}
	fi
    done

    CDATE=$(${NDATE} ${CINC} ${CDATE})
done

exit ${ERR}
