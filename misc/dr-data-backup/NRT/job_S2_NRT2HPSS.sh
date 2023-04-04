#!/bin/bash --login
#SBATCH -J nrt2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 23:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/nrt2hpss.txt
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/nrt2hpss.txt

module load hpss
set -x

SDATE=2016053100
EDATE=2016060100
CINC=24
EXPNAME=
FIELDS="gdas enkfgdas"
#R1 F2 20210629 - 20220630 global-workflow-CCPP2-Chem-NRT-clean
#R2 F1 20210629 - 20220630 global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst
HERADIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/expRuns/
HERADATADIR=${HERADIR}/${EXPNAME}/dr-data-backup
HPSSDATADIR=${HPSSDIR}/${EXPNAME}/dr-data-backup
TMPDIR=${HERADATADIR}/tmp-mv2hpss
FAILEDREC=${HERADATADIR}/tmp-mv2hpss/Record.Failed
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

[[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}

    HPSSFILEDIR=${HERADATADIR}/${CY}/${CY}${CM}/
    hsi "mkdir -p ${HPSSFILEDIR}"
 
    for FIELD in ${FIELDS}; do
        HERAFILEDIR=${HERADATADIR}/${FIELD}.${CY}${CM}${CD}
        HPSSFILE=${HERAFILEDIR}/${FIELD}.${CY}${CM}${CD}.tar 
        cd ${HERAFILEDIR}
	htar -cv -f ${HPSSFILE} *
	ERR=$?
	if [ ${ERR} != 0 ]; then
	    echo ${CDATE}  >> ${FAILEDREC}
	    #rm -rf ${HERAFILEDIR}
        else
	    echo "-------${CDATE} ${FIELD} completed and move on-------"
	fi
    done

    CDATE=$(${NDATE} ${CINC} ${CDATE})
done

exit ${ERR}
