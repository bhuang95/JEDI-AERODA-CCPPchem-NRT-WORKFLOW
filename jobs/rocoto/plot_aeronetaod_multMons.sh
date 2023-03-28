#!/bin/bash --login
#SBATCH --account=wrf-chem
#SBATCH --qos=batch
#SBATCH -n 1
#SBATCH --time=00:59:00
#SBATCH --job-name=timeSeries
#SBATCH --output=./pythonJob.out
#SBATCH --partition=service

export OMP_NUM_THREADS=1
#set -x 

module purge
module load intel/2022.1.2
module load matlab
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest
module load imagemagick/7.0.8-53

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

CDATE=${CDATE:-"2022040600"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
#NRTDIAG=`pwd`
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
sampTmpDir=${diagDir}/collSample/${CDATE}
plotTmpDir=${diagDir}/pyPlot/${CDATE}

[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}
[[ ! -d ${daDir} ]] && mkdir -p ${daDir}
[[ ! -d ${nodaDir} ]] && mkdir -p ${nodaDir}
[[ ! -d ${plotDir} ]] && mkdir -p ${plotDir}
[[ ! -d ${sampTmpDir} ]] && mkdir -p ${sampTmpDir}
[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}


lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do

nrtLoc=${nrtDir}/${modName}/${lpCyc}/${modDomain}/
nrtPlot_sep=${nrtLoc}/AERONET-AOD_full_0m_f000_sep.png
nrtPlot_com=${nrtLoc}/AERONET-AOD_full_0m_f000.png

edCyc=`${NDATE} 18  ${lpCyc}`
stCyc=`${NDATE} -${day30Inc}  ${edCyc}`

mon=`echo ${edCyc} | cut -c1-6`
fstDay=${mon}'0100'
edCyc_1=`${NDATE} -6  ${fstDay}`
newmon=`echo ${edCyc_1} | cut -c1-6`
stCyc_1=${newmon}'0100'  #`${NDATE} -${day30Inc}  ${edCyc_1}`
nrtLoc_1=${nrtDir}/${modName}/months/${edCyc_1}/${modDomain}/
nrtPlot_1=${nrtLoc_1}/AERONET-AOD_full_0m_f000_mon.png

mon=`echo ${edCyc_1} | cut -c1-6`
fstDay=${mon}'0100'
edCyc_2=`${NDATE} -6  ${fstDay}`
newmon=`echo ${edCyc_2} | cut -c1-6`
stCyc_2=${newmon}'0100'  #`${NDATE} -${day30Inc}  ${edCyc_2}`
nrtLoc_2=${nrtDir}/${modName}/months/${edCyc_2}/${modDomain}/
nrtPlot_2=${nrtLoc_2}/AERONET-AOD_full_0m_f000_mon.png

mon=`echo ${edCyc_2} | cut -c1-6`
fstDay=${mon}'0100'
edCyc_3=`${NDATE} -6  ${fstDay}`
newmon=`echo ${edCyc_3} | cut -c1-6`
stCyc_3=${newmon}'0100'  #`${NDATE} -${day30Inc}  ${edCyc_3}`
nrtLoc_3=${nrtDir}/${modName}/months/${edCyc_3}/${modDomain}/
nrtPlot_3=${nrtLoc_3}/AERONET-AOD_full_0m_f000_mon.png

mon=`echo ${edCyc_3} | cut -c1-6`
fstDay=${mon}'0100'
edCyc_4=`${NDATE} -6  ${fstDay}`
newmon=`echo ${edCyc_4} | cut -c1-6`
stCyc_4=${newmon}'0100'  #`${NDATE} -${day30Inc}  ${edCyc_4}`
nrtLoc_4=${nrtDir}/${modName}/months/${edCyc_4}/${modDomain}/
nrtPlot_4=${nrtLoc_4}/AERONET-AOD_full_0m_f000_mon.png

mon=`echo ${edCyc_4} | cut -c1-6`
fstDay=${mon}'0100'
edCyc_5=`${NDATE} -6  ${fstDay}`
newmon=`echo ${edCyc_5} | cut -c1-6`
stCyc_5=${newmon}'0100'  #`${NDATE} -${day30Inc}  ${edCyc_5}`
nrtLoc_5=${nrtDir}/${modName}/months/${edCyc_5}/${modDomain}/
nrtPlot_5=${nrtLoc_5}/AERONET-AOD_full_0m_f000_mon.png

mon=`echo ${edCyc_5} | cut -c1-6`
fstDay=${mon}'0100'
edCyc_6=`${NDATE} -6  ${fstDay}`
newmon=`echo ${edCyc_6} | cut -c1-6`
stCyc_6=${newmon}'0100'  #`${NDATE} -${day30Inc}  ${edCyc_6}`
nrtLoc_6=${nrtDir}/${modName}/months/${edCyc_6}/${modDomain}/
nrtPlot_6=${nrtLoc_6}/AERONET-AOD_full_0m_f000_mon.png

#edCyc_arr=(${edCyc_1} ${edCyc_2} ${edCyc_3} ${edCyc_4} ${edCyc_5} )
#stCyc_arr=(${stCyc_1} ${stCyc_2} ${stCyc_3} ${stCyc_4} ${stCyc_5} )
#nrtLoc_arr=(${nrtLoc_1} ${nrtLoc_2} ${nrtLoc_3} ${nrtLoc_4} ${nrtLoc_5} )
#nrtPlot_arr=(${nrtPlot_1} ${nrtPlot_2} ${nrtPlot_3} ${nrtPlot_4} ${nrtPlot_5} )
edCyc_arr=(${edCyc_1} ${edCyc_2})
stCyc_arr=(${stCyc_1} ${stCyc_2})
nrtLoc_arr=(${nrtLoc_1} ${nrtLoc_2})
nrtPlot_arr=(${nrtPlot_1} ${nrtPlot_2})

echo 'STEP-1: Run Matlab code to collect samples'
rm -rf ${sampTmpDir}/*

cd ${sampTmpDir}
cp ${pyDir}/collect_aeronet_aod_lon_lat_obs_hfx_500nm.m ${sampTmpDir}

nodabckgSamp=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
dabckgSamp=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
daanalSamp=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt

#if [[ ! -f ${nrtPlot_6} ]]; then   
#    ctCyc=${stCyc_6}
#if [[ ! -f ${nrtPlot_5} ]]; then   
#    ctCyc=${stCyc_5}
#elif [[ ! -f ${nrtPlot_4} ]]; then   
#    ctCyc=${stCyc_4}
#elif [[ ! -f ${nrtPlot_3} ]]; then 
#    ctCyc=${stCyc_3}
if [[ ! -f ${nrtPlot_2} ]]; then 
    ctCyc=${stCyc_2}
elif [[ ! -f ${nrtPlot_1} ]]; then 
    ctCyc=${stCyc_1}
else
    ctCyc=${stCyc}
fi

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
    
    ctCyc=`${NDATE} ${cycInc}  ${ctCyc}`
done

###Collect saumples over past 30 days before ${lpCyc}
ctCyc=${stCyc}
nodabckgSamp=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
dabckgSamp=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
daanalSamp=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc}-${edCyc}-wav-500.txt
while [[ ${ctCyc} -le ${edCyc} ]]; do
    nodabckgFile=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc}-${ctCyc}-wav-500.txt
    dabckgFile=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc}-${ctCyc}-wav-500.txt
    daanalFile=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc}-${ctCyc}-wav-500.txt
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

### Collect the past months
for ipmon in ${!nrtPlot_arr[@]}; do
    nrtPlot_tmp=${nrtPlot_arr[ipmon]}
    ctCyc_tmp=${stCyc_arr[ipmon]}
    stCyc_tmp=${stCyc_arr[ipmon]}
    edCyc_tmp=${edCyc_arr[ipmon]}

    if [[ ! -f ${nrtPlot_tmp} ]]; then   
        nodabckgSamp=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc_tmp}-${edCyc_tmp}-wav-500.txt
        dabckgSamp=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc_tmp}-${edCyc_tmp}-wav-500.txt
        daanalSamp=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${stCyc_tmp}-${edCyc_tmp}-wav-500.txt
        while [[ ${ctCyc_tmp} -le ${edCyc_tmp} ]]; do
            nodabckgFile=${nodaExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc_tmp}-${ctCyc_tmp}-wav-500.txt
            dabckgFile=${daExp}-cntlBckg-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc_tmp}-${ctCyc_tmp}-wav-500.txt
            daanalFile=${daExp}-cntlAnal-AERONETAOD-aeronet-lon-lat-obs-hofx-Cyc-${ctCyc_tmp}-${ctCyc_tmp}-wav-500.txt
            if [[ ${ctCyc_tmp} -eq ${stCyc_tmp} ]]; then
                cp ${nodaDir}/${nodabckgFile} ${plotTmpDir}/${nodabckgSamp}
                cp ${daDir}/${dabckgFile} ${plotTmpDir}/${dabckgSamp}
                cp ${daDir}/${daanalFile} ${plotTmpDir}/${daanalSamp}
            else
                cat ${nodaDir}/${nodabckgFile} >> ${plotTmpDir}/${nodabckgSamp}
                cat ${daDir}/${dabckgFile} >> ${plotTmpDir}/${dabckgSamp}
                cat ${daDir}/${daanalFile} >> ${plotTmpDir}/${daanalSamp}
            fi
            ctCyc_tmp=`${NDATE} ${cycInc}  ${ctCyc_tmp}`
        done
    fi
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

echo "Step-3: Run Python code to plot AERONET scatter density figures"
cd ${plotTmpDir}
cp ${pyDir}/plt_aeronet_aod_obs_hfx_MPL_pdf_500nm.py ${plotTmpDir}

### Plot samples over past 30 days before ${lpcYC}
echo ${stCyc} > DATES.info
echo ${edCyc} > DATEE.info
echo "NO" > PASTMONTH.info
python plt_aeronet_aod_obs_hfx_MPL_pdf_500nm.py
ERR=$?
if [[ ${ERR} -eq 0 ]]; then
    echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
    echo "Run python plotting codes succesfully and move figures at ${edCyc}"
    [[ ! -d ${nrtLoc} ]] && mkdir -p ${nrtLoc}
    mv  AERONET-AOD_full_0m_f000.png ${nrtPlot_sep}
else
    echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
    echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
    exit ${ERR}
fi

### Plot samples over the past first month
for ipmon in ${!nrtPlot_arr[@]}; do
    nrtPlot_tmp=${nrtPlot_arr[ipmon]}
    nrtLoc_tmp=${nrtLoc_arr[ipmon]}
    ctCyc_tmp=${stCyc_arr[ipmon]}
    stCyc_tmp=${stCyc_arr[ipmon]}
    edCyc_tmp=${edCyc_arr[ipmon]}
    if [[ ! -f ${nrtPlot_tmp} ]]; then
        echo ${stCyc_tmp} > DATES.info
        echo ${edCyc_tmp} > DATEE.info
        echo "YES" > PASTMONTH.info
        python plt_aeronet_aod_obs_hfx_MPL_pdf_500nm.py
        ERR=$?
        if [[ ${ERR} -eq 0 ]]; then
            echo "**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**_**"
            echo "Run python plotting codes succesfully and move figures at ${edCyc_tmp}"
            [[ ! -d ${nrtLoc_tmp} ]] && mkdir -p ${nrtLoc_tmp}
            mv  AERONET-AOD_full_0m_f000.png ${nrtPlot_tmp}
        else
            echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
            echo "Failed running python plotting codes at ${edCyc_tmp} and exit ${ERR}"
            exit ${ERR}
        fi
    fi
done

### Plot samples over the past first month
### Merge three figures into one
cp ${nrtPlot_sep} ./aeronet_scatter_000.png
#for ipmon in ${!nrtPlot_arr[@]}; do
#    nrtPlot_tmp=${nrtPlot_arr[ipmon]}
#    cp ${nrtPlot_tmp} ./${ipmon}.png
#done

ls ${nrtDir}/${modName}/months/ > months_plots_tmp.info
pre_mons_tmp=`tac months_plots_tmp.info`
pre_mons=""
for pre_mon in ${pre_mons_tmp}; do
   if [[ ${pre_mon} > "2021080100" && ${pre_mon} < ${lpCyc} ]]; then
       pre_mons=${pre_mons}" ${pre_mon}"
   fi
done

pi=0
for pre_mon in ${pre_mons};do
    pi=$((pi+1))
    itmp=$(printf "%03d" ${pi})
    cp ${nrtDir}/${modName}/months/${pre_mon}/full/AERONET-AOD_full_0m_f000_mon.png aeronet_scatter_${itmp}.png
done

pi=$((pi+1))
[[ -f combined.png ]] && rm -rf combined.png
montage aeronet_scatter_???.png  -tile 1x${pi} -geometry 1000x combined.png
ERR=$?
if [[ ${ERR} -eq 0 ]]; then
    echo "Montage is successful and continue"
else
    echo "Montage failed and exit"
    exit ${ERR}
fi
mv  combined.png ${nrtPlot_com}

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
    [[ ! -d ${nrtLoc} ]] && mkdir -p ${nrtLoc}
    mv  AERONET-AOD-BIAS-RMSE_full_0m_f000.png  ${nrtLoc}/
    mv  AERONET-AOD-MAE-BRRMSE_full_0m_f000.png  ${nrtLoc}/
else
    echo ">>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>_<<_>>"
    echo "Failed running python plotting codes at ${edCyc} and exit ${ERR}"
    exit ${ERR}
fi

lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done

exit 0
