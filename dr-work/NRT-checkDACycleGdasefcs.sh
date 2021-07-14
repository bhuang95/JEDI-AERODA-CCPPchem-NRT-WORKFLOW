#!/bin/bash

module load rocoto

daXml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml
daDb=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db

gdasAnaXml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml 
gdasAnaDb=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db

statLog=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-checkDACycleGdasefcs.log

deadGdasefcsLog=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-deadGdasefcs.log
deadGdasefcsRecord=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/logs/xmlLog/NRT-deadGdasefcs.record

caseEnkf=C96
gdasAna=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/${caseEnkf}

ensNum=4

#rocotostat -w ${daXml} -d ${daDb} > ${statLog}

grep DEAD ${statLog} | grep gdasefcs | awk -F " " '{print $1 $2}' > ${deadGdasefcsLog}

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
    grpNum=$(echo ${line} | cut -c21-22)

    if ( ! grep "${cycDate} ${grpNum}" ${deadGdasefcsRecord} ); then

        cycYMD=$(echo ${cycDate} | cut -c1-8)
        cycH=$(echo ${cycDate} | cut -c9-10)

        memEnd=$((grpNum * ensNum))
        memBeg=$((memEnd - ensNum + 1))

        mem0=${memBeg}
        while [[ ${mem0} -le ${memEnd} ]]; do
            mem1=`printf %03d ${mem0}`
	    mem="mem${mem1}"
	    memDir=${gdasAna}/enkfgdas.${cycYMD}/${cycH}/${mem}
	    echo ${memDir}
	    # rm -rf ${memDir}
	    mem0=$[$mem0+1]
        done

        echo "rocotorewind -w ${gdasAnaXml} -d ${gdasAnaDb} -c ${cycDate} -t gdasensprepmet${grpNum}"
        echo "rocotorewind -w ${daXml} -d ${daDb} -c ${cycDate} -t gdasenscalcinc${grpNum}"
        echo "rocotorewind -w ${daXml} -d ${daDb} -c ${cycDate} -t gdasefcs${grpNum}"
        echo "rocotorun -w ${gdasAnaXml} -d ${gdasAnaDb} -c ${cycDate} -t gdasensprepmet${grpNum}"

        #rocotorewind -w ${gdasAnaXml} -d ${gdasAnaDb} -c ${cycDate} -t gdasensprepmet${grpNum}
        #rocotorewind -w ${daXml} -d ${daDb} -c ${cycDate} -t gdasenscalcinc${grpNum}
        #rocotorewind -w ${daXml} -d ${daDb} -c ${cycDate} -t gdasefcs${grpNum}

        #rocotorun -w ${gdasAnaXml} -d ${gdasAnaDb} -c ${cycDate} -t gdasensprepmet${grpNum}
        echo "${cycDate} ${grpNum}"  >> ${deadGdasefcsRecord}
    else
        echo "Already tried cycle ${cycDate} and skip"
    fi
done
	
#mv ${deadGdasefcsLog} ${deadGdasefcsLog}-${cycDate}

exit 0
