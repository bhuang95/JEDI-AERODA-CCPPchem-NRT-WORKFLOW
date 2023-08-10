#!/bin/bash
#set -x

module load rocoto

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
viirs_date=`cat /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/viirs.record` 
modis_date=`${NDATE} -6 ${viirs_date}`
prep_modis_log=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/modis.rocotostat.log
prep_modis_dead_record=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.deadPrepModis

#
prep_modis_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-MODIS.xml
prep_modis_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-MODIS.db
prep_modis_dead_record=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.deadPrepModis

prep_aeronet_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-AERONET.xml
prep_aeronet_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-AERONET.db

hfx_cntl_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/NRT-cntlFreeFcst-dr-data-backup.xml
hfx_cntl_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/NRT-cntlFreeFcst-dr-data-backup.db

hfx_da_xml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.xml
hfx_da_db=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.db


/apps/rocoto/1.3.3/bin/rocotostat -w ${prep_modis_xml} -d ${prep_modis_db} -c ${modis_date}00  -t gdasprepaodobs > ${prep_modis_log}
if ( ! grep SUCCEEDED ${prep_modis_log} ); then
    cdate=${modis_date}
    echo ${cdate}
    echo ${cdate}00 >> ${prep_modis_dead_record}

    /apps/rocoto/1.3.3/bin/rocotocomplete -w ${prep_modis_xml} -d ${prep_modis_db} -c ${cdate}00 -t gdasprepaodobs
    #/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_cntl_xml} -d ${hfx_cntl_db} -c ${cdate}00 -m gdasaodluts
    #/apps/rocoto/1.3.3/bin/rocotocomplete -w ${hfx_da_xml} -d ${hfx_da_db} -c ${cdate}00 -m gdasaodluts
    #/apps/rocoto/1.3.3/bin/rocotoboot -w ${prep_aeronet_xml} -d ${prep_aeronet_db} -c ${cdate}00 -t gdasprepaodobs
fi
exit 0
