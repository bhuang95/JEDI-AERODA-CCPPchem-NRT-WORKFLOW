#!/bin/bash
##SBATCH -n 1
##SBATCH -t 00:30:00
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.err


set -x 

JEDIdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20210701/build/
tmpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/aeronetLog/
outdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/aodObs/MODIS-NRT-/
aeronetdir=/home/Bo.Huang/JEDI-2020/miscScripts-home/JEDI-Support/aeronetScript/readAeronet/
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
source ${JEDIdir}/jedi_module_base.hera
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${JEDIdir}/lib"

module load python/3.7.5
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

sdate=2021072000
cycInc=6

if [ ! -s ${tmpdir}/analdate.info ] ; then
    echo ${sdate} > ${tmpdir}/analdate.info
fi

cycN=`cat ${tmpdir}/analdate.info`
cycN1=`${incdate} ${cycInc}  ${cycN}`
currTime=`date '+%Y%m%d%H'`
echo ${cycN}-${cycN1}-${currTime}
if [ ${cycN1} -lt ${currTime} ]; then
    echo "Start to donwload AERONET AOD at ${cycN}.."
else
    echo "Too early to donwload AERONET AOD at ${cycN} and wait."
    exit 0
fi

cycY=`echo ${cycN} | cut -c 1-4`
cycM=`echo ${cycN} | cut -c 5-6`
cycD=`echo ${cycN} | cut -c 7-8`
cycH=`echo ${cycN} | cut -c 9-10`

cycDate=${cycY}:${cycM}:${cycD}T${cycH}:00:00

outfile_v1=${tmpdir}/MODIS-NRT_AOD_AERONET.${cycN}.v1.nc
outfile_v2=${tmpdir}/MODIS-NRT_AOD_AERONET.${cycN}.nc
python ${aeronetdir}/aeronet.py -i ${cycDate} -o ${outfile_v1}
err=$?

if [ ${err} != '0' ]; then
    echo "aeronet.py failed at ${cycN} and exit!"
    exit 1
else
    echo "aeronet.py succeeded at ${cycN} and proceed to next step!"
fi

${JEDIdir}/bin/ioda-upgrade.x ${outfile_v1} ${outfile_v2}
err=$?
if [ ${err} != '0' ]; then
    echo "ioda-upgrade.x failed at ${cycN} and exit!"
    exit 1
else
    echo "ioda-upgrade.x succeeded at ${cycN} and move data!"
    mkdir -p ${outdir}/${cycN}
    /bin/mv ${outfile_v2} ${outdir}/${cycN}/
    /bin/rm -rf ${outfile_v1}
    echo ${cycN} >> ${tmpdir}/analdate.record
    cycN=`${incdate} ${cycInc}  ${cycN}`
    echo ${cycN} > ${tmpdir}/analdate.info
fi

exit 0
