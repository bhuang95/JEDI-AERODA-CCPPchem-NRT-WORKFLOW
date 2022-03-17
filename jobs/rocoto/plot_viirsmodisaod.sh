#!/bin/bash --login
##SBATCH --account=chem-var
##SBATCH --qos=debug
##SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
##SBATCH --time=00:29:00
##SBATCH --job-name=timeSeries
##SBATCH --output=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/nrt_viirsModis.log


export OMP_NUM_THREADS=1
#set -x 

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

ulimit -s unlimited

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CDATE=${CDATE:-"2021072000"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}

lpsCyc=${CDATE}
lpeCyc=${CDATE}

day1Inc=24
cycInc=6

modName=${NRTMODEL}
nrtDir=${NRTDIAG}
nrtDirTmp=${NRTDIAGTMP}
modDomain=${MODELDOMAIN}
diagDir=${nrtDirTmp}/viirsModisAod
plotTmpDir=${diagDir}/pyPlot
pyDir=${HOMEgfs}/plots/

[[ ! -d ${nrtDirTmp} ]] && mkdir -p ${nrtDirTmp}
[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}
[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do
    echo ${lpCyc}
    nrtPlot=${nrtDir}/${modName}/${lpCyc}/${modDomain}/
    cp ${pyDir}/plt_viirs_modis_aod_global_daily_display_separate.py ${plotTmpDir}
    cd ${plotTmpDir}
    python plt_viirs_modis_aod_global_daily_display_separate.py ${lpCyc}
    ERR=$?
    if [[ ${ERR} -eq 0 ]]; then
        echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
	echo "Run python plotting codes succesfully and move figures at ${lpCyc}"
	[[ ! -d ${nrtPlot} ]] && mkdir -p ${nrtPlot}
	mv  viirsAod.png ${nrtPlot}/viirsAod_full_0m_f006.png
	mv  modisAod.png ${nrtPlot}/modisAod_full_0m_f006.png
	mv  viirsAodBias.png ${nrtPlot}/viirsAodBias_full_0m_f006.png
	mv  modisAodBias.png ${nrtPlot}/modisAodBias_full_0m_f006.png
    else
        echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
	echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
	exit ${ERR}
    fi
    lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done
exit 0

