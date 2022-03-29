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

#ulimit -s unlimited

CDATE=${CDATE:-"2021072000"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}

lpsCyc=${CDATE}
lpeCyc=${CDATE}


modName=${NRTMODEL}
modDomain=${MODELDOMAIN}
nrtDir=${NRTDIAG}
curDir=`pwd`


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do
    echo ${lpCyc}
    nrtPlot=${nrtDir}/${modName}/${lpCyc}/${modDomain}
    cd ${nrtPlot}
    if [[ -f VIIRS_MODIS_AOD_full_0m_f000.png && -f VIIRS_MODIS_AOD_BIAS_full_0m_f000.png && -f AERONET_AOD_full_0m_f000.png  && -f AERONET_AOD_BIAS_RMSE_full_0m_f000.png && -f AERONET_AOD_MAE_BRRMSE_full_0m_f000.png ]]; then
        zip -n .png files.zip * -i \*.png
	ERR=$?
        if [[ ${ERR} -eq 0 ]]; then
	    echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
	    echo "Files at was zipped successfullly at ${lpCyc}"
	else
	    echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
	    echo "Failed compressing files at ${lpCyc} and exit ${ERR}"
	    exit ${ERR}
	fi
    else
        echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
	echo "Files are not complete at ${lpCyc} and exit"
	exit 1
    fi
    lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done

sleep 60

exit 0
