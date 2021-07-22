#!/bin/bash
module load rocoto


# NRT run for GBBEPx bin2nc conversion 
rocotostat -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/NRT-cntlFreeFcst-hofxModis.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/NRT-cntlFreeFcst-hofxModis.db | more
#rocotostat_log.out

