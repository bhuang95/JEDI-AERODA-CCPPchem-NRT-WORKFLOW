#!/bin/bash --login
#SBATCH -J hpss-offline
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-offline-out.txt
#SBATCH -e ./hpss-offline-err.txt

module load hpss

expName=global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst
dataDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data/
gbbDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata//GBBEPx/
icsDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata//gdasAna/
obsDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata//aodObs//VIIRS-C192/
caseCntl=C96
caseEnkf=C96
gbbShift=TRUE
gbbShiftHr=-24
tmpDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data//hpssTmp
bakupDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data//../dr-data-backup
logDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data//logs
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanal=20
cycN=`cat cyc_date.info`
#cycN=2022051206
cycN1=`${incdate} 6 ${cycN}`
if [ ${gbbShift} == "TRUE" ]; then
    cycGBB=`${incdate} ${gbbShiftHr} ${cycN}`
else
    cycGBB=${cycN}
fi

mkdir -p ${tmpDir}
mkdir -p ${bakupDir}

#hpssDir=/ESRL/BMC/wrf-chem/5year/Bo.Huang/JEDIFV3-AERODA/expRuns/
hpssDir=/BMC/fim/5year/MAPP_2018/bhuang/expRuns/
hpssExpDir=${hpssDir}/${expName}/dr-data/
hsi "mkdir -p ${hpssExpDir}"

echo ${cycN}
cycY=`echo ${cycN} | cut -c 1-4`
cycM=`echo ${cycN} | cut -c 5-6`
cycD=`echo ${cycN} | cut -c 7-8`
cycH=`echo ${cycN} | cut -c 9-10`
cycYMD=`echo ${cycN} | cut -c 1-8`

echo ${cycN1}
cyc1Y=`echo ${cycN1} | cut -c 1-4`
cyc1M=`echo ${cycN1} | cut -c 5-6`
cyc1D=`echo ${cycN1} | cut -c 7-8`
cyc1H=`echo ${cycN1} | cut -c 9-10`
cyc1YMD=`echo ${cycN1} | cut -c 1-8`
cyc1prefix=${cyc1YMD}.${cyc1H}0000

echo ${cycGBB}
cycGBBY=`echo ${cycGBB} | cut -c 1-4`
cycGBBM=`echo ${cycGBB} | cut -c 5-6`
cycGBBD=`echo ${cycGBB} | cut -c 7-8`
cycGBBH=`echo ${cycGBB} | cut -c 9-10`
cycGBBYMD=`echo ${cycGBB} | cut -c 1-8`
cycGBBprefix=${cycGBBYMD}.${cycGBBH}0000

cntlGDAS=${dataDir}/gdas.${cycYMD}/${cycH}/

if [ -s ${cntlGDAS} ]; then
### Copy the logfiles
#    /bin/cp -r ${logDir}/${cycN} ${cntlGDAS}/${cycN}_log

### Clean unnecessary cntl files
#    /bin/rm -rf ${cntlGDAS}/gdas.t??z.logf???.txt

### Backup cntl data
#    cntlBakup=${bakupDir}/gdas.${cycYMD}/${cycH}/
#
#    mkdir -p ${cntlBakup}
#
#    anaCntlTmpDir=${cntlGDAS}/anaCntl
#    mkdir -p ${anaCntlTmpDir}
#    cp -r ${icsDir}/${caseCntl}/gdas.${cycYMD}/${cycH}/RESTART/* ${anaCntlTmpDir}/
#
#    gbbCntlTmpDir=${cntlGDAS}/gbbCntl
#    mkdir -p ${gbbCntlTmpDir}
#    cp -r ${gbbDir}/${caseCntl}/${cycGBBYMD} ${gbbCntlTmpDir}/
#
#    /bin/cp -r ${cntlGDAS}/* ${cntlBakup}/
    #/bin/cp ${cntlGDAS}/obs/* ${cntlBakup}/
#    #/bin/cp ${cntlGDAS}/RESTART/*.fv_aod_* ${cntlBakup}/
#    #/bin/cp ${cntlGDAS}/RESTART/${cyc1prefix}.coupler.res.* ${cntlBakup}/
#    #/bin/cp ${cntlGDAS}/RESTART/${cyc1prefix}.fv_tracer.* ${cntlBakup}/
#    #/bin/cp ${cntlGDAS}/RESTART/${cyc1prefix}.fv_core.* ${cntlBakup}/
#
#    if [ $? != '0' ]; then
#       echo "Copy Control gdas.${cycYMD}${cycH} failed and exit at error code $?"
#       exit $?
#    fi
    
    #htar -cv -f ${hpssExpDir}/gdas.${cycN}.tar ${cntlGDAS}
    cd ${cntlGDAS}
    htar -cv -f ${hpssExpDir}/gdas.${cycN}.tar *
    #hsi ls -l ${hpssExpDir}/gdas.${cycN}.tar
    stat=$?
    if [ ${stat} != '0' ]; then
       echo "HTAR failed at gdas.${cycN}  and exit at error code ${stat}"
	exit ${stat}
    else
       echo "HTAR at gdas.${cycN} completed !"
       /bin/rm -rf  ${cntlGDAS}   #./gdas.${cycN}
    fi

    cycN=`${incdate} ${cycInc}  ${cycN}`
fi
exit 0
