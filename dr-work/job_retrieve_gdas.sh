#!/bin/bash
module load rocoto
module load hpss

ufsdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-CCPP2-Chem/gsd-ccpp-chem/sorc/UFS_UTILS_20220203/UFS_UTILS/util/gdas_init 
datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/

gdasanaxml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml
gdasanadb=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db
grpnums="01 02 03 04 05"

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#submit missing job at cyc and cyc+6
sdate=2023022506
edate=2023022512
ctmp=1

jobhpss='NO'
jobmove='YES'
jobroc='NO'

cdate=${sdate}
while [ ${cdate} -le ${edate} ]; do
    echo ${cdate}
    echo ${ctmp}
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


### Submit job to grab GDAS analysis  from HPSS
    if [ ${jobhpss} = 'YES' ]; then 
        rm -rf ${tmpdir}/*
        cd ${ufsdir}
        ./driver.hera_hpssDownload.sh  ${cdate} ${tmpdir} 
    fi

### Move data out of ${tmpdir}
    if [ ${jobmove} = 'YES' ]; then 
        srcdir=${tmpdir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}
        detdir=${datadir}/enkfgdas.${gyy}${gmm}${gdd}/
        mkdir -p ${detdir}
        mv ${srcdir} ${detdir}
        err=$?
        if [ $err -ne 0 ]; then
            echo 'Move ensemble failed'
            echo ${cdate}
            echo ${ctmp}
            exit 1
        fi

        srcdir=${tmpdir}/gdas.${cyy}${cmm}${cdd}/${chh}
        detdir=${datadir}/gdas.${cyy}${cmm}${cdd}/
        mkdir -p ${detdir}
        mv ${srcdir} ${detdir}
        err=$?
        if [ $err -ne 0 ]; then
            echo 'Move control failed'
            echo ${cdate}
            echo ${ctmp}
            exit 1
        fi
    fi

### resubmit job 
    if [ ${jobroc} = 'YES' ]; then
        if [ ${gdate} -ge ${sdate} ] && [ ${gdate} -le ${edate} ]; then
	    rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${gdate}00 -m gdasensprepmet
	    #rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${gdate}00 -t gdasprepmet
            #for grpnum in ${grpnums}; do
            #    rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${gdate}00 -t gdasensprepmet${grpnum}
            #done
	fi
    fi
cdate=`${incdate} 6 ${cdate}`
ctmp=$((ctmp  + 1))

done
exit

