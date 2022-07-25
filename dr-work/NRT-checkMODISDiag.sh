#!/bin/bash
#set -x

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

if [[ -s ${prep_modis_dead}-${cycDate} ]]; then
    echo "Already resubmitted and exit"
    exit 0
fi

if [[ -s ${prep_modis_log} ]]; then
    rm -rf ${prep_modis_log}
fi

/apps/rocoto/1.3.3/bin/rocotostat -w ${prep_modis_xml} -d ${prep_modis_db} > ${prep_modis_log}

grep DEAD ${prep_modis_log} | awk -F " " '{print $1 $2 $6}' > ${prep_modis_dead}

if [[ -s ${prep_modis_dead} ]]; then
    lines=$(cat ${prep_modis_dead})
else
    echo "${prep_modis_dead} is empty and exit"
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
	echo "${prep_modis_xml}"
	echo "${prep_modis_db}"
	echo "${cycDate}"
	echo "${jobTask}"
        /apps/rocoto/1.3.3/bin/rocotocomplete -w ${prep_modis_xml} -d ${prep_modis_db} -c ${cycDate} -t ${jobTask}
	/apps/rocoto/1.3.3/bin/rocotoboot -w ${prep_aeronet_xml} -d ${prep_aeronet_db} -c ${cycDate} -t ${jobTask}
	/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_cntl_xml} -d ${hfx_cntl_db} -c ${cycDate} -t gdasaodluts01
	/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cycDate} -t gdasaodluts01
	/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cycDate} -t gdasaodluts02
	/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cycDate} -t gdasaodluts03
	/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cycDate} -t gdasaodluts04
	/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cycDate} -t gdasaodluts05
    fi
done
	
mv ${prep_modis_dead} ${prep_modis_dead}-${cycDate}

exit 0
