#!/bin/bash --login
##SBATCH --account=chem-var
##SBATCH --qos=debug
##SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
##SBATCH --time=00:29:00
##SBATCH --job-name=timeSeries
##SBATCH --output=./nrt_NASAECMWF.log


export OMP_NUM_THREADS=1
set -x 

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

ulimit -s unlimited
module purge
module load intel/2022.1.2
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CDATE=${CDATE:-"2022051800"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}
NASAECDIR=${NASAECDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/metPlusDiag/metPlusOutput-AOD/"}
MISSNASAAOD_RECORD=${MISSNASAAOD_RECORD:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/missingNASAAOD.record"}
MISSECAOD_RECORD=${MISSECAOD_RECORD:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/missingECAOD.record"}
CYMD=$(echo ${CDATE} | cut -c1-8)
NASAMISSING="NO"
ECMISSING="NO"


if ( grep ${CYMD} ${MISSNASAAOD_RECORD} );then
    NASAMISSING="YES"
fi

if ( grep ${CYMD} ${MISSECAOD_RECORD} );then
    ECMISSING="YES"
fi

if [[ ${NASAMISSING} == "YES" && ${NASAMISSING} == "YES" ]]; then
    echo "Missing both NASA and ECMWF AOD and exit"
    exit 0
fi


lpsCyc=${CDATE}
lpeCyc=${CDATE}

day1Inc=24
cycInc=6

modName=${NRTMODEL}
nrtDir=${NRTDIAG}
nrtDirTmp=${NRTDIAGTMP}
modDomain=${MODELDOMAIN}
diagDir=${nrtDirTmp}/nasaEcmwfAod
plotTmpDir=${diagDir}/${CDATE}
pyDir=${HOMEgfs}/plots/

[[ ! -d ${nrtDirTmp} ]] && mkdir -p ${nrtDirTmp}
[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}
[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do
    echo ${lpCyc}
    lpCyc_YMD=`echo ${lpCyc} | cut -c 1-8`
    nrtPlot=${nrtDir}/${modName}/${lpCyc}/${modDomain}/

    NODABCKG_NASA=${NASAECDIR}/NRT-NODA-cntlBckg_NASAana/${lpCyc_YMD}/aod_sigLevhPa.nc
    DABCKG_NASA=${NASAECDIR}/NRT-DA-cntlBckg_NASAana/${lpCyc_YMD}/aod_sigLevhPa.nc
    DAANAL_NASA=${NASAECDIR}/NRT-DA-cntlAnal_NASAana/${lpCyc_YMD}/aod_sigLevhPa.nc

    NODABCKG_EC=${NASAECDIR}/NRT-NODA-cntlBckg_ECana/${lpCyc_YMD}/aod_sigLevhPa.nc
    DABCKG_EC=${NASAECDIR}/NRT-DA-cntlBckg_ECana/${lpCyc_YMD}/aod_sigLevhPa.nc
    DAANAL_EC=${NASAECDIR}/NRT-DA-cntlAnal_ECana/${lpCyc_YMD}/aod_sigLevhPa.nc

    cp ${pyDir}/plt_nasa_ec_aod_2dmap_550nm.py ${plotTmpDir}
    cd ${plotTmpDir}
    python plt_nasa_ec_aod_2dmap_550nm.py ${lpCyc} ${NASAMISSING} ${ECMISSING} ${NODABCKG_NASA} ${DABCKG_NASA} ${DAANAL_NASA} ${NODABCKG_EC} ${DABCKG_EC} ${DAANAL_EC}
    ERR=$?
    if [[ ${ERR} -eq 0 ]]; then
        echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
	echo "Run python plotting codes succesfully and move figures at ${lpCyc}"
	[[ ! -d ${nrtPlot} ]] && mkdir -p ${nrtPlot}
        mv  NASA-ECMWF-AOD_full_0m_f000.png NASA-ECMWF-AOD-BIAS_full_0m_f000.png NASA-ECMWF-AOD-RMSE_full_0m_f000.png ${nrtPlot}/
    else
        echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
	echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
	exit ${ERR}
    fi
    lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done
exit 0

