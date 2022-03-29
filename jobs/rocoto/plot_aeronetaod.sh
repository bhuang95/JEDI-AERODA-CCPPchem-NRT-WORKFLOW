#!/bin/bash --login
##SBATCH --account=wrf-chem
##SBATCH --qos=batch
##SBATCH -n 1
##SBATCH --time=00:59:00
##SBATCH --job-name=timeSeries
##SBATCH --output=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/logs/pythonJob.out
##SBATCH --output=./pythonJob.out
##SBATCH --partition=service

export OMP_NUM_THREADS=1
set -x 

module purge
module load intel/2022.1.2
module load matlab
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

CDATE=${CDATE:-"2021072000"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}

lpsCyc=${CDATE}
lpeCyc=${CDATE}
day30Inc=720 # in hour
day1Inc=24 # in hour
cycInc=6 # in hour

modName=${NRTMODEL}
nrtDir=${NRTDIAG}
nrtDirTmp=${NRTDIAGTMP}
modDomain=${MODELDOMAIN}
diagDir=${nrtDirTmp}/aeronetCollSamples
pyDir=${HOMEgfs}/plots/

daExp=global-workflow-CCPP2-Chem-NRT-clean
nodaExp=global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst

daDir=${diagDir}/Samples/${daExp}
nodaDir=${diagDir}/Samples/${nodaExp}
plotDir=${diagDir}/scaDenFigs
sampTmpDir=${diagDir}/collSample
plotTmpDir=${diagDir}/pyPlot/${CDATE}

[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}
[[ ! -d ${daDir} ]] && mkdir -p ${daDir}
[[ ! -d ${nodaDir} ]] && mkdir -p ${nodaDir}
[[ ! -d ${plotDir} ]] && mkdir -p ${plotDir}
[[ ! -d ${sampTmpDir} ]] && mkdir -p ${sampTmpDir}
[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do

nrtPlot=${nrtDir}/${modName}/${lpCyc}/${modDomain}

edCyc=`${NDATE} 18  ${lpCyc}`
stCyc=`${NDATE} -${day30Inc}  ${edCyc}`
echo ${stCyc}
echo ${edCyc}

echo 'STEP-1: Run Matlab code to collect samples'
rm -rf ${sampTmpDir}/*

cd ${sampTmpDir}
cp ${pyDir}/collect_aeronet_aod_lon_lat_obs_hfx_500nm.m ${sampTmpDir}

nodabckgSamp=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
dabckgSamp=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
daanalSamp=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt

ctCyc=${stCyc}
while [[ ${ctCyc} -le ${edCyc} ]]; do
    echo ${ctCyc}
    echo ${ctCyc} > DATE.info
    nodabckgFile=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc}-${ctCyc}-wav-500.txt
    dabckgFile=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc}-${ctCyc}-wav-500.txt
    daanalFile=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc}-${ctCyc}-wav-500.txt

    if [[ -f ${nodaDir}/${nodabckgFile} && -f ${daDir}/${dabckgFile} && ${daDir}/${daanalFile} ]]; then
        echo "++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++_++"
	echo "Already collected samples and pass at ${ctCyc}"
    else
	matlab -nodisplay  -r "try; collect_aeronet_aod_lon_lat_obs_hfx_500nm; catch; materr=1; quit(materr); end; quit(0)"
	ERR=$?
	if [[ ${ERR} -eq 0 ]]; then
            echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
	    echo "Collect samples succesfully and move files at ${ctCyc}"
	    mv ${nodabckgFile} ${nodaDir}/${nodabckgFile}
	    mv ${dabckgFile} ${daDir}/${dabckgFile}
	    mv ${daanalFile} ${daDir}/${daanalFile}
	else
            echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
	    echo "Failed collecting samples at ${ctCyc} and exit ${ERR}"
	    exit ${ERR}
        fi
    fi
    
    if [[ ${ctCyc} -eq ${stCyc} ]]; then
        cp ${nodaDir}/${nodabckgFile} ${plotTmpDir}/${nodabckgSamp}
        cp ${daDir}/${dabckgFile} ${plotTmpDir}/${dabckgSamp}
        cp ${daDir}/${daanalFile} ${plotTmpDir}/${daanalSamp}
    else
        cat ${nodaDir}/${nodabckgFile} >> ${plotTmpDir}/${nodabckgSamp}
        cat ${daDir}/${dabckgFile} >> ${plotTmpDir}/${dabckgSamp}
        cat ${daDir}/${daanalFile} >> ${plotTmpDir}/${daanalSamp}
    fi
    ctCyc=`${NDATE} ${cycInc}  ${ctCyc}`
done

echo "Step-2: Run Python code to collect AERONET station samples"
cd ${plotTmpDir}
cp ${pyDir}/collect_aeronet_aod_count_obs_hfx_bias_rmse_mae_brrmse_500nm_ave.py ${plotTmpDir}
echo ${stCyc} > DATES.info
echo ${edCyc} > DATEE.info

python collect_aeronet_aod_count_obs_hfx_bias_rmse_mae_brrmse_500nm_ave.py
ERR=$?
if [[ ${ERR} -eq 0 ]]; then
    echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
    echo "Collecting AERONET station samples at ${edCyc}"
else
    echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
    echo "Failed collecting AERONET station samples  at ${edCyc} and exit ${ERR}"
    exit ${ERR}
fi

echo "Step-2: Run Python code to plot AERONET scatter density figures"
cd ${plotTmpDir}
cp ${pyDir}/plt_aeronet_aod_obs_hfx_pdf_500nm.py ${plotTmpDir}
echo ${stCyc} > DATES.info
echo ${edCyc} > DATEE.info

python plt_aeronet_aod_obs_hfx_pdf_500nm.py
ERR=$?
if [[ ${ERR} -eq 0 ]]; then
    echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
    echo "Run python plotting codes succesfully and move figures at ${edCyc}"
    [[ ! -d ${nrtPlot} ]] && mkdir -p ${nrtPlot}
    mv  AERONET_AOD_full_0m_f000.png ${nrtPlot}/
else
    echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
    echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
    exit ${ERR}
fi

echo "Step-4: Run Python code to plot AERONET AOD bias and RMSE	 over a map"
cd ${plotTmpDir}
cp ${pyDir}/plt_aeronet_aod_count_bias_rmse_mae_brrmse_500nm_ave.py  ${plotTmpDir}
echo ${stCyc} > DATES.info
echo ${edCyc} > DATEE.info

python plt_aeronet_aod_count_bias_rmse_mae_brrmse_500nm_ave.py
ERR=$?
if [[ ${ERR} -eq 0 ]]; then
    echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
    echo "Run python ploting AERONET bias and RMSE and  move figures at ${edCyc}"
    #mv AERONET-scatter-density-${edCyc}.png ${plotDir}
    [[ ! -d ${nrtPlot} ]] && mkdir -p ${nrtPlot}
    mv  AERONET_AOD_BIAS_RMSE_full_0m_f000.png  ${nrtPlot}/
    mv  AERONET_AOD_MAE_BRRMSE_full_0m_f000.png  ${nrtPlot}/
else
    echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
    echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
    exit ${ERR}
fi

lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done

exit 0
