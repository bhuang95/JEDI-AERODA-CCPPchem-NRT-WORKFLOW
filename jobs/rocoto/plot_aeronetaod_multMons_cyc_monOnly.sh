#!/bin/bash --login
#SBATCH --account=wrf-chem
#SBATCH --qos=batch
#SBATCH -n 1
#SBATCH --time=08:00:00
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

#CDATE=${CDATE:-"2022040600"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
NRTDIAG=${NRGDIAG:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/"}
#NRTDIAG=`pwd`
NRTDIAGTMP=${NRGDIAGTMP:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/nrtWebDisplay/"}
NRTMODEL=${NRTMODEL:-"GEFS-Aerosols_JEDI_AOD_DA"}
MODELDOMAIN=${MODELDOMAIN:-"full"}

lpsCyc=2023020300
lpeCyc=2023020300
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

[[ ! -d ${diagDir} ]] && mkdir -p ${diagDir}
[[ ! -d ${daDir} ]] && mkdir -p ${daDir}
[[ ! -d ${nodaDir} ]] && mkdir -p ${nodaDir}
[[ ! -d ${plotDir} ]] && mkdir -p ${plotDir}

lpCyc=${lpsCyc}
while [[ ${lpCyc} -le ${lpeCyc} ]]; do

plotTmpDir=${diagDir}/pyPlot/${lpCyc}
sampTmpDir=${diagDir}/collSample/${lpCyc}

[[ ! -d ${plotTmpDir} ]] && mkdir -p ${plotTmpDir}
[[ ! -d ${sampTmpDir} ]] && mkdir -p ${sampTmpDir}

nrtLoc=${nrtDir}/${modName}/${lpCyc}/${modDomain}/
nrtPlot_sep=${nrtLoc}/AERONET-AOD_full_0m_f000_sep.png
nrtPlot_com=${nrtLoc}/AERONET-AOD_full_0m_f000.png

edCyc=`${NDATE} 18  ${lpCyc}`
stCyc=`${NDATE} -${day30Inc}  ${edCyc}`

### Collect the past months
mondir="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/diagPlots/GEFS-Aerosols_JEDI_AOD_DA/months"
stCyc_arr=(2021080100 2021090100 2021100100 2021110100 2021120100 2022010100 2022020100 2022030100 2022040100 2022050100 2022060100 2022070100 2022080100 2022090100 2022100100 2022110100 2022120100 2023010100)
edCyc_arr=(2021083118 2021093018 2021103118 2021113018 2021123118 2022013118 2022022818 2022033118 2022043018 2022053118 2022063018 2022073118 2022083118 2022093018 2022103118 2022113018 2022123118 2023013118)
cp ${pyDir}/plt_aeronet_aod_obs_hfx_MPL_pdf_500nm.py ${plotTmpDir}
cd ${plotTmpDir}
for ipmon in ${!stCyc_arr[@]}; do
    ctCyc_tmp=${stCyc_arr[ipmon]}
    stCyc_tmp=${stCyc_arr[ipmon]}
    edCyc_tmp=${edCyc_arr[ipmon]}

    nrtPlot=${mondir}/${edCyc_tmp}/full/
    mkdir -p ${nrtPlot}

    echo ${ctCyc_tmp}
    echo ${ctCyc_tmp} > DATES.info
    echo ${edCyc_tmp} > DATEE.info
    echo "YES" > PASTMONTH.info

    #if [[ ! -f ${nrtPlot_tmp} ]]; then   
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
    python plt_aeronet_aod_obs_hfx_MPL_pdf_500nm.py
    mv  AERONET-AOD_full_0m_f000.png ${nrtPlot}/AERONET-AOD_full_0m_f000_mon.png
    err=$?
    if [[ ${err} -eq 0 ]]; then
       echo "${ctCyc_tmp} passed"
       rm -rf *.txt *.info
    else
       echo "${ctCyc_tmp} failed and exit"
       exit 100
    fi
    #fi
done
lpCyc=`${NDATE} ${day1Inc}  ${lpCyc}`
done

exit
