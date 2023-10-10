#!/bin/bash

module load rocoto

#XMLFILE=NRT-cntlFreeFcst-dr-data-backup.xml
#XMLDIR=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/
#DBFILE=NRT-cntlFreeFcst-dr-data-backup.db
#DBDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/

XMLFILE=NRT-DACycle-dr-data-backup.xml
XMLDIR=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work
DBFILE=NRT-DACycle-dr-data-backup.db
DBDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/

TASK=gdasaodluts_aeronet01
SDATE=2023081300
EDATE=2023081506
CYCINTHR=6
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    rocotocomplete -w ${XMLDIR}/${XMLFILE} -d ${DBDIR}/${DBFILE} -c ${CDATE}00 -t ${TASK}
    #echo "-w ${XMLDIR}/${XMLFILE} -d ${DBDIR}/${DBFILE} -c ${CDATE}00 -t ${TASK}"
    CDATE=$(${NDATE} +${CYCINTHR} ${CDATE})
done 

