#!/bin/bash


#Alert:
#After runining this scrpt, manually run if the queue is debug

###/apps/rocoto/1.3.3/bin/rocotoboot -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db -c ${cdate}00 -m gdasaodluts
###/apps/rocoto/1.3.3/bin/rocotoboot -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work-cntlFreeFcst/NRT-cntlFreeFcst.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst/dr-work/NRT-cntlFreeFcst.db -c ${cdate}00 -m gdasaodluts

expdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/
ndate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanals=20
tiles="1 2 3 4 5 6"
cdate=2022091412
bdate=`${ndate} -6 ${cdate}`
prep_viirs_dead_record=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.missAllVIIRS

echo ${cdate}00 >> ${prep_viirs_dead_record}

/apps/rocoto/1.3.3/bin/rocotocomplete -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepAODOBS.db -c ${cdate}00 -t gdasprepaodobs

/apps/rocoto/1.3.3/bin/rocotocomplete -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db -c ${cdate}00 -t gdasanal
/apps/rocoto/1.3.3/bin/rocotocomplete -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db -c ${cdate}00 -t gdaseupd
/apps/rocoto/1.3.3/bin/rocotocomplete -w /home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-DACycle.db -c ${cdate}00 -t enkfrecenter


cymd=`echo ${cdate} | cut -c 1-8`
ch=`echo ${cdate} | cut -c 9-10`

bymd=`echo ${bdate} | cut -c 1-8`
bh=`echo ${bdate} | cut -c 9-10`

cntldir=${expdir}/gdas.${bymd}/${bh}/
ensdir=${expdir}/enkfgdas.${bymd}/${bh}/

tprefix=${cymd}.${ch}0000

nanal=-1
while [ ${nanal} -le ${nanals} ]; do
    if [ ${nanal} -eq -1 ]; then
        memstr=""
	expdir=${cntldir}
    elif [ ${nanal} -eq 0 ]; then
	memstr=ensmean
	expdir=${ensdir}
    else
	memstr=mem`printf %03d $nanal`
	expdir=${ensdir}
    fi

    memdir=${expdir}/${memstr}/RESTART/
    cd ${memdir}
    for itile in ${tiles}; do
       echo ${tprefix}.fv_tracer.res.tile${itile}.nc.ges
       #ls ${memdir}/${tprefix}.fv_tracer.res.tile${itile}.nc.ges
      /bin/cp ${tprefix}.fv_tracer.res.tile${itile}.nc.ges ${tprefix}.fv_tracer.res.tile${itile}.nc
      #echo ${memdir}/${bymd}.${bh}0000.fv_tracer.res.tile${itile}.nc.ges
      #echo ${memdir}/${bymd}.${bh}0000.fv_tracer.res.tile${itile}.nc
    done
   
    nanal=$[$nanal+1]
done

#files=`ls *.ges`
#
#for file in ${files}
#do
#    echo ${file}
#    filenew=`echo ${file} | rev | cut -d. -f2- | rev` 
#    /bin/cp ${file} ${filenew}
#done

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "run gdasaodluts job for both DA and NODA only FV3-Grid" 
exit
