#!/bin/bash
set -x

module load rocoto

xmlFile=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODANA.xml
dbFile=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODANA.db


statLog=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-checkAODAnalysis.log

deadGdasefcsLog=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-deadAODAnalysis.log
deadGdasefcsRecord=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-deadAODAnalysis.record

/apps/rocoto/1.3.3/bin/rocotostat -w ${xmlFile} -d ${dbFile} > ${statLog}

grep DEAD ${statLog} | awk -F " " '{print $1 $2}' > ${deadGdasefcsLog}

if [[ -s ${deadGdasefcsLog} ]]; then
    lines=$(cat ${deadGdasefcsLog})
else
    echo "${deadGdasefcsLog} is empty and exit"
    exit 0
fi

### Rerun gdas analysis processing
for line in ${lines}; do
    echo ${line}
    cycDate=$(echo ${line} | cut -c1-12)
    jobTask=$(echo ${line} | cut -c13-)

    echo "rocotorewind -w ${xmlFile} -d ${dbFile} -c ${cycDate} -t ${jobTask}"
/apps/rocoto/1.3.3/bin/rocotorewind -w ${xmlFile} -d ${dbFile} -c ${cycDate} -t ${jobTask}
done
	
mv ${deadGdasefcsLog} ${deadGdasefcsLog}-${cycDate}

exit 0
