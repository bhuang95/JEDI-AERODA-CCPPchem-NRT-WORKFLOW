#!/bin/bash
set -x

#module load rocoto

#NRT run for VIIRS2IODA conversion
echo "NRT run for VIIRS2IODA conversion"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS.db

#NRT run for MODIS2IODA conversion
echo "NRT run for MODIS2IODA conversion"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-MODIS.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-MODIS.db

#NRT run for AERONET2IODA conversion
echo "NRT run for AERONET2IODA conversion"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-AERONET.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS-AERONET.db

# NRT run for GBBEPx bin2nc conversion 
echo "NRT run for GBBEPx bin2nc conversion"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-genGBBEPx.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-genGBBEPx.db

# NRT run for GDAS analysis and sfc processing
#echo "NRT run for GDAS analysis and sfc processing"
#/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db

# NRT run for DA cycling 
echo "NRT run for DA cycling "
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db

# NRT run for cntlFreeFcst
echo "NRT run for cntlFreeFcst"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/NRT-cntlFreeFcst.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/NRT-cntlFreeFcst.db

# run MODIS hofx for  cntlFreeFcst
echo "run MODIS hofx for  cntlFreeFcst"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/NRT-cntlFreeFcst-dr-data-backup.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/NRT-cntlFreeFcst-dr-data-backup.db

# NRT run for DA cycling MODIS hofx
echo "NRT run for DA cycling MODIS hofx"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle-dr-data-backup.db

# Check and resubmit failed ensemble forecast
echo "Check and resubmit failed ensemble forecast"
/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-checkDACycleGdasefcs.sh

# NRT run for diagnostics plot
echo "NRT run for diagnostics plot"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-diagPlot.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-diagPlot.db


#NRT run for AOD analysis processing
echo "NRT run for AOD analysis processing"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODANA.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODANA.db

# Check and resubmit failed aod analysis
echo "Check and resubmit failed aod analysis"
/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-checkAODAnalysis.sh

# Check and resuvmit failed MODIS AOD
echo "Check and resuvmit failed MODIS AOD"
/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-checkMODISDiag.sh
