#!/bin/bash --login
##SBATCH --account=chem-var
##SBATCH --qos=debug
##SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
##SBATCH --time=00:29:00
##SBATCH --job-name=timeSeries
##SBATCH --output=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/nrt_viirsModis.log


export OMP_NUM_THREADS=1
set -x 

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

ulimit -s unlimited
module purge
module load intel/2022.1.2
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CDATE=${CDATE:-"2021072000"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}
AODMISSING=${AODMISSING:-"NONE"}
MISSMODIS_RECORD=${MISSMODIS_RECORD:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.deadPrepModis"}
CYMD=$(echo ${CDATE} | cut -c1-8)

#if ( grep ${CYMD} ${MISSMODIS_RECORD} );then
#    AODMISSING="MODIS"
#fi

lpsCyc=${CDATE}
lpeCyc=${CDATE}

### Can be removed later
lpeCyc_18=`${NDATE} 18  ${lpeCyc}`

CYMD_18=`echo "${lpeCyc_18}" | cut -c1-8`
CH_18=`echo "${lpeCyc_18}" | cut -c9-10`

RUNDIR_18=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns
PSLOT_18=global-workflow-CCPP2-Chem-NRT-clean
PSLOT1_18=global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst

ROTDIR_18=${RUNDIR_18}/${PSLOT_18}/dr-data/gdas.${CYMD_18}/${CH_18}/obs/
ROTDIR1_18=${RUNDIR_18}/${PSLOT1_18}/dr-data/gdas.${CYMD_18}/${CH_18}/obs/

ROTDIR_BAK_18=${RUNDIR_18}/${PSLOT_18}/dr-data-backup/gdas.${CYMD_18}/${CH_18}/obs/
ROTDIR1_BAK_18=${RUNDIR_18}/${PSLOT1_18}/dr-data-backup/gdas.${CYMD_18}/${CH_18}/obs/

[[ ! -d ${ROTDIR_BAK_18} ]] && mkdir -p ${ROTDIR_BAK_18}
[[ ! -d ${ROTDIR1_BAK_18} ]] && mkdir -p ${ROTDIR1_BAK_18}

if ( ! ls ${ROTDIR_BAK_18}/aod_viirs_npp_hofx_3dvar_LUTs_* ); then
    /bin/cp -r ${ROTDIR_18}/aod_viirs_npp_hofx_3dvar_LUTs_* ${ROTDIR_BAK_18}
fi

if ( ! ls ${ROTDIR1_BAK_18}/aod_viirs_npp_hofx_3dvar_LUTs_* ); then
    /bin/cp -r ${ROTDIR1_18}/aod_viirs_npp_hofx_3dvar_LUTs_* ${ROTDIR1_BAK_18}
fi

###

day1Inc=24
cycInc=6

modName=${NRTMODEL}
nrtDir=${NRTDIAG}
nrtDirTmp=${NRTDIAGTMP}
modDomain=${MODELDOMAIN}
diagDir=${nrtDirTmp}/viirsModisAod
plotTmpDir=${diagDir}/pyPlot/${CDATE}
pyDir=${HOMEgfs}/plots/

[[ ! -d ${nrtDirTmp} ]] && mkdir -p ${nrtDirTmp}
[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}
[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do
    echo ${lpCyc}
    nrtPlot=${nrtDir}/${modName}/${lpCyc}/${modDomain}/
    cp ${pyDir}/plt_viirs_modis_aod_bias_global_550nm.py ${plotTmpDir}
    cd ${plotTmpDir}
    python plt_viirs_modis_aod_bias_global_550nm.py ${lpCyc} ${AODMISSING}
    ERR=$?
    if [[ ${ERR} -eq 0 ]]; then
        echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
	echo "Run python plotting codes succesfully and move figures at ${lpCyc}"
	[[ ! -d ${nrtPlot} ]] && mkdir -p ${nrtPlot}
	mv  VIIRS-MODIS-AOD_full_0m_f000.png VIIRS-MODIS-AOD-BIAS_full_0m_f000.png  ${nrtPlot}/
    else
        echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
	echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
	exit ${ERR}
    fi
    lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done
exit 0

