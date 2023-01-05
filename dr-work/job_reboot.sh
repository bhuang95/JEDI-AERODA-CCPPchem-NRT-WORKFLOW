#!/bin/bash
module load rocoto
module load hpss


xmlfile='/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODANA.xml'
dbfile='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODANA.db'
task='prepaodana_ec'

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#submit missing job at cyc and cyc+6
sdate=2022090700
edate=2022102200
cycinc=24

cdate=${sdate}
while [ ${cdate} -le ${edate} ]; do
    echo ${cdate}

    gdate=`${incdate} -6 ${cdate}`

    tmpdir=${datadir}/tmp${ctmp}

    cyy=`echo ${cdate} | cut -c 1-4`
    cmm=`echo ${cdate} | cut -c 5-6`
    cdd=`echo ${cdate} | cut -c 7-8`
    chh=`echo ${cdate} | cut -c 9-10`

    gyy=`echo ${gdate} | cut -c 1-4`
    gmm=`echo ${gdate} | cut -c 5-6`
    gdd=`echo ${gdate} | cut -c 7-8`
    ghh=`echo ${gdate} | cut -c 9-10`

    rocotoboot -w ${xmlfile} -d ${dbfile} -c ${cdate}00 -t ${task}

    cdate=`${incdate} ${cycinc} ${cdate}`

done
exit

