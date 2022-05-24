#!/bin/bash --login
#SBATCH --account=chem-var
#SBATCH --qos=batch
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH --time=08:00:00
#SBATCH --job-name=timeSeries
#SBATCH --output=./nrt_viirsModis.log


export OMP_NUM_THREADS=1
#set -x 

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

ulimit -s unlimited
module purge
module load intel/2022.1.2
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

#SDATES=2021100100
#EDATES=2021123100

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}
AODMISSING=${AODMISSING:-"NONE"}


lpsCyc=2021100300
lpeCyc=2022043000

VIIRSMISSING="2022041900"
MODISMISSING="2021102200 2021111800 20220108002022031700 2022050800 2022050900 2022051100 2022052100 2022052200 2022052300"

day1Inc=24
cycInc=6

modName=${NRTMODEL}
nrtDir=${NRTDIAG}
nrtDirTmp=${NRTDIAGTMP}
modDomain=${MODELDOMAIN}
diagDir=${nrtDirTmp}/viirsModisAod
pyDir=${HOMEgfs}/plots/

[[ ! -d ${nrtDirTmp} ]] && mkdir -p ${nrtDirTmp}
[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do
    echo ${lpCyc}

    plotTmpDir=${diagDir}/pyPlot/${lpCyc}

[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}

    AODMISSING="NONE"
    
    for MISS in ${VIIRSMISSING}; do
        if [[ ${lpCyc} == ${MISS} ]]; then
            AODMISSING="VIIRS"
	fi
    done

    for MISS in ${MODISMISSING}; do
        if [[ ${lpCyc} == ${MISS} ]]; then
            AODMISSING="MODIS"
	fi
    done

    for MISS1 in ${VIIRSMISSING}; do
    for MISS2 in ${MODISMISSING}; do
        if [[ ${lpCyc} == ${MISS1} && ${lpCyc} == ${MISS2} ]]; then
            AODMISSING="VIIRSMODIS"
	fi
    done
    done

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

