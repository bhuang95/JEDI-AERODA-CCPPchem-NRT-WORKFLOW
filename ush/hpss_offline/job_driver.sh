#!/bin/bash

#topdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/hpssTmp/hpss_offline
#jobscri='job_hpss_offline_DA.sh'
topdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-data/hpssTmp/hpss_offline
jobscri='job_hpss_offline_NODA.sh'

misscycs='
2021091718
2022040318
2022040400
2022040406
2022040412
2022040418
2022040500
2022040506
2022041818
2022041900
2022041906
2022041912
2022041918
2022050200
2022050206
2022050212
2022050218
2022050300
2022050306
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



