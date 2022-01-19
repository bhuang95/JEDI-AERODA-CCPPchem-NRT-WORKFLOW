#!/bin/bash
module load rocoto


# NRT run for GBBEPx bin2nc conversion 
rocotostat -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.db | less 
#rocotostat_log.out

