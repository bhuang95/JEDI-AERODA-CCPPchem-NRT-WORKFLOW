#!/bin/bash


#---------------------------------------------------------------------
# Driver script for running on Hera.
#
# Edit the 'config' file before running.
#---------------------------------------------------------------------

set -x
#sdate=$1
#edate=$2
#ufsdir=$3
#tmpdir=$4
#topdir=$5

topdir=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/misc/fromHPSS/GDASfromHPSS/v16.3/pastcycs_gdas_enkf
ufsdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-CCPP2-Chem/gsd-ccpp-chem/sorc/UFS_UTILS_20220203/UFS_UTILS/util/gdas_init 
tmpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/

gdasanaxml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml
gdasanadb=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db

#cd ${ufsdir}
compiler=${compiler:-"intel"}
source ${ufsdir}/../../sorc/machine-setup.sh > /dev/null 2>&1
module use ${ufsdir}/../../modulefiles
module load build.$target.$compiler
module list

# Needed for NDATE utility
module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
module load prod_util/1.1.0
module load rocoto
module load hpss

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

####################################################
cd ${topdir}
#submit missing job at cyc and cyc+6
#echo '2023051500' > ${topdir}/record_sdate.txt
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
    rm -rf ${tmpdir}/enkfgdas.????????
    rm -rf ${tmpdir}/gdas.????????
    rm -rf ${tmpdir}/tmp_??????????
fi

sdate=$(${incdate} 24 ${sdate_old})	
edate=$(${incdate} 24 ${sdate})

echo ${sdate} > ${topdir}/record_sdate.txt
echo ${edate} > ${topdir}/record_edate.txt

###############################################
PROJECT_CODE=wrf-chem
QUEUE=batch

#source config_hpssDownload
###
EXTRACT_DATA=yes
LEVS=65
CDUMP=gdas
gfs_ver=v16

CRES_HIRES=C96
CRES_ENKF=C96
UFS_DIR=${ufsdir}/../..

export  UFS_DIR  CRES_HIRES CRES_ENKF
export LEVS gfs_ver
###

cdate=${sdate}
DEPEND="-d afterok"
while [ ${cdate} -le ${edate} ]; do

    export EXTRACT_DIR=${tmpdir}/tmp_${cdate}
    export yy=`echo ${cdate} | cut -c 1-4`
    export mm=`echo ${cdate} | cut -c 5-6`
    export dd=`echo ${cdate} | cut -c 7-8`
    export hh=`echo ${cdate} | cut -c 9-10`

    if [ $EXTRACT_DATA == yes ]; then

        rm -fr $EXTRACT_DIR
        mkdir -p $EXTRACT_DIR

        MEM=6000M
        WALLT="2:00:00"

      DATAH=$(/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_${CDUMP} \
       -o ${tmpdir}/log.data.${CDUMP} -e ${tmpdir}/log.data.${CDUMP} ${topdir}/get_v16.data.hpssDownload.sh ${CDUMP})
      DEPEND=${DEPEND}":$DATAH"

      if [ "$CDUMP" = "gdas" ] ; then
        DATA1=$(/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp1 \
         -o ${tmpdir}/log.data.grp1 -e ${tmpdir}/log.data.grp1 ${topdir}/get_v16.data.hpssDownload.sh grp1)
        DATA2=$(/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp2 \
         -o ${tmpdir}/log.data.grp2 -e ${tmpdir}/log.data.grp2 ${topdir}/get_v16.data.hpssDownload.sh grp2)
        DEPEND=${DEPEND}":$DATA1:$DATA2"
      fi
    fi
    cdate=`${incdate} 6 ${cdate}`
done

echo "DEPEND=${DEPEND}"

WALLT="0:30:00"
/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 -t $WALLT -A $PROJECT_CODE -q $QUEUE -J move_gdas_${sdate}_${edate} \
       -o ${tmpdir}/log.move_gdas_${sdate}_${edate} -e ${tmpdir}/log.move_gdas_${sdate}_${edate} ${DEPEND} ${topdir}/mv_files_rocotoboot_jobs.sh

err=$?

if [ $err != 0 ]; then
    echo "Submit mv_files_rocotoboot_jobs.sh at ${sdate}-${edate} failed and exit"
    exit 1
fi

exit $err
