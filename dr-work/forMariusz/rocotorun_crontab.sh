#!/bin/bash

# Define your location
# *.xml directory
xmldir=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/forMariusz
# Corresponding *db directory
dbdir=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/forMariusz

set -x


# Important notes
# If you apply rocotocomplete to any cycles and for any jobs, please keep record of this cycle for each job separately. I will need to in the cycling run in the future. 

echo "Run GBBEPx"
# Origional data directory on Hera: /scratch2/BMC/public/data/grids/nesdis/GBBEPx/C96
# If data missing or missing some cycles, manually rocotocomplete and record this cycle. It will automatically move to next cycle.
/apps/rocoto/1.3.3/bin/rocotorun -w ${xmldir}/NRT-genGBBEPx-Mariusz.xml -d ${dbdir}/NRT-genGBBEPx-Mariusz.db

echo "Run VIIRS AOD converter"
# VIIRS AOD data on Hera: /scratch2/BMC/public/data/sat/nesdis/viirs/aod/conus/
# When CDATE + 12 hours exists, this job will run automatically.
# Sometimes it is not exactly satisfied, e.g., only a portion of data available at at [CDATE-3, CDATE+3] hours (mannually check), you need to rocotoboot this cycle,
# If all data missing at [CDATE-3, CDATE+3] hours missing, you need to manually rocotocomplete and record this cycle. it will move to next cycle automatically.
/apps/rocoto/1.3.3/bin/rocotorun -w ${xmldir}/NRT-prepAODOBS-Mariusz.xml -d ${dbdir}/NRT-prepAODOBS-Mariusz.db

echo "Run MODIS AOD converter"
# MODIS AOD data: /scratch2/BMC/public/data/sat/nasa/modis/aerosol
# When CDATE + 12 hours exists, run this job.
# Sometimes it is not exactly satisfied, e.g., only a portion of data available at at [CDATE-3, CDATE+3] hours (manually check), you need to rocotoboot this cycle,
# If all data missing at [CDATE-3, CDATE+3] hours missing, you need to manually rocotocomplete and record this cycle. It will move to next cycle automatically.
/apps/rocoto/1.3.3/bin/rocotorun -w ${xmldir}/NRT-prepAODOBS-MODIS-Mariusz.xml -d ${dbdir}/NRT-prepAODOBS-MODIS-Mariusz.db

echo "Run GDAS processing"
# Mirrored data on Hera: /scratch1/NCEPDEV/rstprod/prod/com//gfs/v16.3/ (only available at the current day and the day before)
#                        /scratch1/BMC/chem-var/pagowski/junk_scp/wcoss2/
# If data missing or missing some cycles, manually rocotocomplete and record this cycle. It will automatically move to next cycle.
/apps/rocoto/1.3.3/bin/rocotorun -w ${xmldir}/NRT-prepGdasAnalSfc-Mariusz.xml -d ${dbdir}/NRT-prepGdasAnalSfc-Mariusz.db


#### Other Important Command ####

#/apps/rocoto/1.3.3/bin/rocotorun -w *.xml -d *.db
## Check job status

#/apps/rocoto/1.3.3/bin/rocotorewind -w *.xml -d *.db -c {cycle} -t Task ( or -m  MetaTask)
## Rewind a job by cleaning records in *.db file

#/apps/rocoto/1.3.3/bin/rocotoboot -w *.xml -d *.db -c {cycle} -t Task ( or -m  MetaTask)
## Force to run a job without considering the dependency. It sometimes required rocotorewind first.


#/apps/rocoto/1.3.3/bin/rocotocomplete -w *.xml -d *.db -c {cycle} -t Task ( or -m  MetaTask)
## Force to complete a job without considering the dependency. 
## It is useful when the dependency is not satisfied and you will to pass this job and move to next job.
## Unsatisfied dependency can include, e.g., missing observations, GDAS data, or GBBEPx
#### If a job is forced, please keep track of this cycle, I will use it later. 
