#!/bin/bash

#module load rocoto

#NRT run for VIIRS2IODA conversion
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS.db

# NRT run for GBBEPx bin2nc conversion 
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-genGBBEPx.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-genGBBEPx.db

# NRT run for GDAS analysis and sfc processing
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db

# NRT run for DA cycling 
#/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db
