#!/bin/bash

#topdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/hpssTmp/hpss_offline
#jobscri='job_hpss_offline_DA.sh'

#topdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data/hpssTmp/hpss_offline
#jobscri='job_hpss_offline_NODA.sh'

#topdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data-backup/hpssTmp/hpss-offline
#jobscri='job_hpss_offline_dr-data-backup_DA.sh'

topdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data-backup/hpssTmp/hpss-offline
jobscri='job_hpss_offline_dr-data-backup_NODA.sh'


misscycs='
2022041900
2022041906
2022041912
2022041918
'

for cyc in ${misscycs}; do
    echo ${cyc}
    cycdir=${topdir}/${cyc}
    mkdir -p ${cycdir}
    cp ${topdir}/${jobscri} ${cycdir}
    cd ${cycdir}
    echo ${cyc} > cyc_date.info
    sbatch ${jobscri}
done



