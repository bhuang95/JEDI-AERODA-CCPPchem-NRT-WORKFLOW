#!/bin/bash
set -x

module load rocoto

prep_modis_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-MODIS.xml
prep_modis_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-MODIS.db
prep_modis_log=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-checkPrepModis.log
prep_modis_dead=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-deadPrepModis.log
prep_modis_dead_record=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/deadPrepModis.record

prep_aeronet_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-AERONET.xml
prep_aeronet_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-AERONET.db

hfx_cntl_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/NRT-cntlFreeFcst-dr-data-backup.xml
hfx_cntl_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/NRT-cntlFreeFcst-dr-data-backup.db

hfx_da_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.xml
hfx_da_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.db


rocotostat -w ${prep_modis_xml} -d ${prep_modis_xml} > ${prep_modis_xml}

grep DEAD ${prep_modis_xml} | awk -F " " '{print $1 $2 $6}' > ${pre_modis_dead}

if [[ -s ${pre_modis_dead} ]]; then
    lines=$(cat ${pre_modis_dead})
else
    echo "${pre_modis_dead} is empty and exit"
    exit 0
fi

### Rerun gdas analysis processing
for line in ${lines}; do
    echo ${line}
    cycDate=$(echo ${line} | cut -c1-12)
    jobTask=$(echo ${line} | cut -c13-26)
    deadNum=$(echo ${line} | cut -c27)

    if [[ ${deadNum} == 5 ]];then
	echo ${cycDate} >> ${prep_modis_dead_record}
	echo "Resubmit MODIS-related jobs at cycle ${cycDate}"
        rocotocomplete -w ${prep_modis_xml} -d ${prep_modis_db} -c ${cycDate} -t ${jobTask}
	rocotoboot -w ${prep_aeronet_xml} -d ${prep_aeronet_db} -c ${cycDate} -t ${jobTask}
	rocotcomplete -w ${hfx_cntl_xml} -d ${hfx_cntl_db} -c ${cycDate} -t gdasaodluts01
	rocotcomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cycDate} -m gdasaodluts
    fi
done
	
mv ${pre_modis_dead} ${pre_modis_dead}-${cycDate}

exit 0
