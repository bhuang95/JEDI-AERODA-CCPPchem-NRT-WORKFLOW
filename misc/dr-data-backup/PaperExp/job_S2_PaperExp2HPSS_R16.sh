#!/bin/bash --login
#SBATCH -J paper2hpss_R16
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 23:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/paper2hpss_R16.txt
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/psper2hpss_R16.txt

module load hpss
set -x

SDATE=2016053100
EDATE=2016063000
CINC=24
FIELDS="gdas"
EXPNAMES="
VIIRSAOD_JEDIENVAR_C96_C96_M20_GBBPEx_yesFRP_IC_201605MODISAOD_201606
"


#R1 F2 0531-0630 NODA_C96_C96_M20_CCPP2_noEmisSPPT_noPert_noAmp_201606
#R2 F2 0531-0630 NODA_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R3 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_GETKF_noRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R4 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_GETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R5 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_LETKF_noRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R6 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_noEmisSPPT_noPert_noAmp_test1_201606
#R7 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_noPert_yesAmp_test1_201606
#R8 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_noAmp_test1_201606
#R9 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R10 F2 0531-0630 VIIRSAOD_JEDI_ENVAR_VTSM3_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606

#R11 F2 0508-0531 NODA_C96_C96_M20_CCPP2_noStochEmis_201605
#R12 F2 0531-0609 VIIRSAOD_JEDI_ENVAR_GETKFInf_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R13 F2 0531-0609 VIIRSAOD_JEDI_ENVAR_LETKFInf_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R14 F2 0531-0609 VIIRSAOD_JEDI_ENVARLOGP_GETKF_noRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606
#R15 F2 0531-0609 VIIRSAOD_JEDI_ENVARLOGP_GETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606

#R16 F1 0531-0630 VIIRSAOD_JEDIENVAR_C96_C96_M20_GBBPEx_yesFRP_IC_201605MODISAOD_201606
for EXPNAME in ${EXPNAMES}; do
echo "**********HBO-${EXPNAME}*************"
HERADIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/expRuns/
HERADATADIR=${HERADIR}/${EXPNAME}/dr-data-backup
HPSSDATADIR=${HPSSDIR}/${EXPNAME}/dr-data-backup 
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
 
    for FIELD in ${FIELDS}; do
        HERAFILEDIR=${HERADATADIR}/${FIELD}.${CY}${CM}${CD}
        #HPSSFILE=${HPSSFILEDIR}/${FIELD}.${CY}${CM}${CD}.tar 
        HPSSFILE=${FIELD}.${CY}${CM}${CD}.tar 
	echo ${HERAFILEDIR}
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
	echo ${ERR}
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
done
exit ${ERR}
