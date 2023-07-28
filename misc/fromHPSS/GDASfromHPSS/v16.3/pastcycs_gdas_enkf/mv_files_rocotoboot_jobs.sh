#!/bin/bash
##SBATCH -A wrf-chem
##SBATCH -t 07:59:00
##SBATCH -p service
##SBATCH -o move.out
##SBATCH -J move_gdas

module load rocoto
set -x 
topdir=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/misc/fromHPSS/GDASfromHPSS/v16/pastcycs_gdas_enkf/
datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/

gdasanaxml=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.xml
gdasanadb=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-work/NRT-prepGdasAnalSfc.db

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#submit missing job at cyc and cyc+6
sdate=$(cat ${topdir}/record_sdate.txt)
edate=$(cat ${topdir}/record_edate.txt)
jobmove='YES'
jobroc='YES'

cdate=${sdate}
while [ ${cdate} -le ${edate} ]; do
    echo ${cdate}
    gdate=`${incdate} -6 ${cdate}`

    tmpdir=${datadir}/tmp_${cdate}

    cyy=`echo ${cdate} | cut -c 1-4`
    cmm=`echo ${cdate} | cut -c 5-6`
    cdd=`echo ${cdate} | cut -c 7-8`
    chh=`echo ${cdate} | cut -c 9-10`

    gyy=`echo ${gdate} | cut -c 1-4`
    gmm=`echo ${gdate} | cut -c 5-6`
    gdd=`echo ${gdate} | cut -c 7-8`
    ghh=`echo ${gdate} | cut -c 9-10`

## Move data out of ${tmpdir}
    if [ ${jobmove} = 'YES' ]; then 
        srcdir=${tmpdir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}
        detdir=${datadir}/enkfgdas.${gyy}${gmm}${gdd}/
	[ ! -d ${detdir} ] && mkdir -p ${detdir} 
        
	echo ${srcdir}
	echo ${detdir}
	echo '+++++++++++++++'
        mv ${srcdir} ${detdir}

        err=$?
        if [ $err -ne 0 ]; then
            echo 'Move ensemble failed'
            echo ${cdate}
            exit 1
        fi

        srcdir=${tmpdir}/gdas.${cyy}${cmm}${cdd}/${chh}
        detdir=${datadir}/gdas.${cyy}${cmm}${cdd}/
	[ ! -d ${detdir} ] && mkdir -p ${detdir} 

	echo ${srcdir}
	echo ${detdir}
	echo '+++++++++++++++'
        mv ${srcdir} ${detdir}

        err=$?
        if [ $err -ne 0 ]; then
            echo 'Move control failed'
            echo ${cdate}
            exit 1
        fi
    fi
    cdate=`${incdate} 6 ${cdate}`

done

## resubmit job 
#cdate=${sdate}
#while [ ${cdate} -lt ${edate} ]; do
#    echo ${cdate}
#    if [ ${jobroc} = 'YES' ]; then
#       echo "rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${cdate}00 -m gdasensprepmet"
#       echo "rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${cdate}00 -t gdasprepmet"
#/apps/rocoto/1.3.3/bin/rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${cdate}00 -m gdasensprepmet
#/apps/rocoto/1.3.3/bin/rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${cdate}00 -t gdasprepmet
#       #for grpnum in ${grpnums}; do
#       #    rocotoboot -w ${gdasanaxml} -d ${gdasanadb} -c ${gdate}00 -t gdasensprepmet${grpnum}
#       #done
#    fi
#    cdate=`${incdate} 6 ${cdate}`
#done
exit $?

