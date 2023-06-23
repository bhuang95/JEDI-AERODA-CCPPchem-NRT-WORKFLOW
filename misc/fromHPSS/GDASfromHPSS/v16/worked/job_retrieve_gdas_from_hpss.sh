#!/bin/bash
module load rocoto
module load hpss

set -x

topdir=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/misc/GDASfromHPSS/v16
ufsdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-CCPP2-Chem/gsd-ccpp-chem/sorc/UFS_UTILS_20220203/UFS_UTILS/util/gdas_init 
datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/

gdasanaxml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml
gdasanadb=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate


cd ${topdir}

#submit missing job at cyc and cyc+6
echo '2023051400' > ${topdir}/record_sdate.txt
sdate_old=$(cat ${topdir}/record_sdate.txt)
edate_old=$(${incdate} 18 ${sdate_old})

rstat=${topdir}/record_rocotostat.txt
[ -e ${rstat} ] && rm -rf ${rstat} 

cdate_old=${sdate_old}
icount=0
while [ ${cdate_old} -le ${edate_old} ]; do
/apps/rocoto/1.3.3/bin/rocotostat -w ${gdasanaxml} -d ${gdasanadb} -c ${cdate_old}00 -t gdasprepmet >> ${rstat}
/apps/rocoto/1.3.3/bin/rocotostat -w ${gdasanaxml} -d ${gdasanadb} -c ${cdate_old}00 -m gdasensprepmet >> ${rstat}
    icount=$((${icount} + 6))
    cdate_old=$(${incdate} 6 ${cdate_old})
done
    
isuccess=$(grep 'SUCCEEDED' ${rstat} | wc -l)

if [ ${isuccess} != ${icount} ]; then
    echo "Cycle ${sdate} failed or not complete and wait..."
#    sleep 6
#cd ${topdir}
#${topdir}/job_retrieve_gdas_from_hpss.sh
    exit 0
else
    echo "Contine to next cycle..."
    rm -rf ${datadir}/enkfgdas.????????
    rm -rf ${datadir}/gdas.????????
    rm -rf ${datadir}/tmp_??????????
fi

sdate=$(${incdate} 24 ${sdate_old})	
edate=$(${incdate} 24 ${sdate})

echo ${sdate} > ${topdir}/record_sdate.txt
echo ${edate} > ${topdir}/record_edate.txt
${topdir}/driver.hera_hpssDownload.sh  ${sdate} ${edate} ${ufsdir} ${datadir} ${topdir}

#sleep 6
#cd ${topdir}
#${topdir}/job_retrieve_gdas_from_hpss.sh
exit $?
