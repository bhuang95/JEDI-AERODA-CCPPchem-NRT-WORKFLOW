#!/bin/bash

expdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/
ndate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanals=20
tiles="1 2 3 4 5 6"
cdate=2022041912
bdate=`${ndate} 6 ${cdate}`

cymd=`echo ${cdate} | cut -c 1-8`
ch=`echo ${cdate} | cut -c 9-10`

bymd=`echo ${bdate} | cut -c 1-8`
bh=`echo ${bdate} | cut -c 9-10`

cntldir=${expdir}/gdas.${cymd}/${ch}/
ensdir=${expdir}/enkfgdas.${cymd}/${ch}/

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
       echo ${bymd}.${bh}0000.fv_tracer.res.tile${itile}.nc.ges
       #ls ${memdir}/${tprefix}.fv_tracer.res.tile${itile}.nc.ges
      /bin/cp ${bymd}.${bh}0000.fv_tracer.res.tile${itile}.nc.ges ${bymd}.${bh}0000.fv_tracer.res.tile${itile}.nc
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

exit
