#!/bin/bash

nanals=20
tiles="1 2 3 4 5 6"
tprefix=20160610.000000

expcntldir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_noAmp_test1_201606/dr-data/gdas.20160609/18
expensdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_noAmp_test1_201606/dr-data/enkfgdas.20160609/18


nanal=-1
while [ ${nanal} -le ${nanals} ]; do
    if [ ${nanal} -eq -1 ]; then
        memstr=""
	expdir=${expcntldir}
    elif [ ${nanal} -eq 0 ]; then
	memstr=ensmean
	expdir=${expensdir}
    else
	memstr=mem`printf %03d $nanal`
	expdir=${expensdir}
    fi

    memdir=${expdir}/${memstr}/RESTART/
    cd ${memdir}
    for itile in ${tiles}; do
       echo ${tprefix}.fv_tracer.res.tile${itile}.nc.ges
       #ls ${memdir}/${tprefix}.fv_tracer.res.tile${itile}.nc.ges
       /bin/cp ${tprefix}.fv_tracer.res.tile${itile}.nc.ges ${tprefix}.fv_tracer.res.tile${itile}.nc
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
