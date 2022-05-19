#!/bin/bash
#SBATCH -J hpss-2016050818
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-2016050818-out.txt
#SBATCH -e ./hpss-2016050818-err.txt

#module load hpss

module load nco

topDir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/
expName=global-workflow-CCPP2-Chem-NRT-clean
backDir=${topDir}/${expName}/dr-data-backup/
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

sdate=2021070100
edate=2022043018
cycInc=6

cycN=${sdate}
while [[ ${cycN} -le ${edate} ]]; do
    echo ${cycN}
    cycY=`echo ${cycN} | cut -c 1-4`
    cycM=`echo ${cycN} | cut -c 5-6`
    cycD=`echo ${cycN} | cut -c 7-8`
    cycH=`echo ${cycN} | cut -c 9-10`
    cycYMD=`echo ${cycN} | cut -c 1-8`

    #cntlGDAS=${backDir}/gdas.${cycYMD}/${cycH}/
    #cd ${cntlGDAS}
    #rm -rf gdas.t??z.atmf006.nc.ges gdas.t??z.sfcf006.nc.ges

    enkfGDAS=${backDir}/enkfgdas.${cycYMD}/${cycH}/
    cd ${enkfGDAS}
    rm -rf mem???/RESTART
    rm -rf ensmean/RESTART

    cycN=`${incdate} ${cycInc}  ${cycN}`
done
exit
