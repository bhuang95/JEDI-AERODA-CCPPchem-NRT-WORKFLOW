#!/bin/bash --login
#SBATCH -J hpss-2022051206
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-2022051206-out.txt
#SBATCH -e ./hpss-2022051206-err.txt

module load hpss

expName=global-workflow-CCPP2-Chem-NRT-clean
dataDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data-backup/
obsDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata//aodObs//MODIS-NRT-/
obsDir_VIIRS=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata//aodObs//VIIRS-C192/
obsDir_AERONET=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata//aodObs//AERONET/
tmpDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data-backup//hpssTmp
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanal=20
cycN=`cat cyc_date.info`
bakupDir=${tmpDir}/dr-data-backup-${cycN}
#cycN=2022051206
cycN1=`${incdate} -6 ${cycN}`

mkdir -p ${tmpDir}

hpssDir=/BMC/fim/5year/MAPP_2018/bhuang/expRuns/
hpssExpDir=${hpssDir}/${expName}/dr-data-backup/
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

cntlGDAS=${dataDir}/gdas.${cycYMD}/${cycH}/

if [ -s ${cntlGDAS} ]; then

### Backup cntl data
    cntlBakup=${bakupDir}/gdas.${cycYMD}/${cycH}/
    mkdir -p ${cntlBakup}/obs
    mkdir -p ${cntlBakup}/RESTART
    /bin/cp -r ${cntlGDAS}/obs/* ${cntlBakup}/obs/
    /bin/cp -r ${cntlGDAS}/RESTART/*.fv_aod_* ${cntlBakup}/RESTART/

    if [ $? != '0' ]; then
       echo "Copy Control gdas.${cycYMD}${cycH} failed and exit at error code $?"
       exit $?
    fi
    

### Start EnKF
    enkfGDAS=${dataDir}/enkfgdas.${cycYMD}/${cycH}/
### Delite unnecessary ens files
    enkfGDAS_Mean=${dataDir}/enkfgdas.${cycYMD}/${cycH}/ensmean
    enkfBakup_Mean=${bakupDir}/enkfgdas.${cycYMD}/${cycH}/ensmean

    mkdir -p ${enkfBakup_Mean}/obs
    mkdir -p ${enkfBakup_Mean}/RESTART
    /bin/cp -r ${enkfGDAS_Mean}/obs/* ${enkfBakup_Mean}/obs/
    /bin/cp -r ${enkfGDAS_Mean}/RESTART/*.fv_aod_* ${enkfBakup_Mean}/RESTART/

    ianal=1
    while [ ${ianal} -le ${nanal} ]; do
       memStr=mem`printf %03i $ianal`

       enkfGDAS_Mem=${dataDir}/enkfgdas.${cycYMD}/${cycH}/${memStr}
       enkfBakup_Mem=${bakupDir}/enkfgdas.${cycYMD}/${cycH}/${memStr}

       mkdir -p ${enkfBakup_Mem}/obs
       mkdir -p ${enkfBakup_Mem}/RESTART
       /bin/cp -r ${enkfGDAS_Mem}/obs/* ${enkfBakup_Mem}/obs/
       /bin/cp -r ${enkfGDAS_Mem}/RESTART/*.fv_aod_* ${enkfBakup_Mem}/RESTART/

       /bin/rm -rf ${enkfGDAS_Mem}/RESTART/*.fv_core.res.*
       /bin/rm -rf ${enkfGDAS_Mem}/RESTART/*.fv_tracer.res.*

       #ls -l ${enkfGDAS_Mem}/RESTART/*.fv_core.res.*
       #ls -l ${enkfGDAS_Mem}/RESTART/*.fv_tracer.res.*

       ianal=$[$ianal+1]

    done

    if [ $? != '0' ]; then
       echo "Copy EnKF enkfgdas.${cycYMD}${cycH} failed and exit at error code $?"
       exit $?
    fi

### Tar preprocessed obs files, sfc data and gbbepx
    obsTmpDir=${bakupDir}/AODobs
    mkdir -p ${obsTmpDir}
    cp -r ${obsDir}/${cycN}/* ${obsTmpDir}/
    cp -r ${obsDir_VIIRS}/${cycN}/* ${obsTmpDir}/
    cp -r ${obsDir_AERONET}/${cycN}/* ${obsTmpDir}/

    if [ $? != '0' ]; then
       echo "Copy AODobs.${cycYMD}${cycH} failed and exit at error code $?"
       exit $?
    fi

    cd ${bakupDir}
    htar -cv -f ${hpssExpDir}/dr-data-backup.${cycN}.tar *
    stat=$?
    echo ${stat}
    if [ ${stat} != '0' ]; then
       echo "HTAR failed at prepdata.${cycN}  and exit at error code ${stat}"
    	exit ${stat}
    else
       echo "HTAR at prepdata.${cycN} completed !"
       echo "YES"  ${tmpDir}/hpss-${cycN}.check
       /bin/rm -rf ${bakupDir}
    fi

    cycN=`${incdate} ${cycInc}  ${cycN}`
fi
exit 0
