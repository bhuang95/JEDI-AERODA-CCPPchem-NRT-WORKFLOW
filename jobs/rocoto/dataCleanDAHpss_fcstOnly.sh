#!/bin/ksh -x

###############################################################
## Abstract:
## Archive driver script
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current analysis date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################

###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base arch"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

hpssTmp=${ROTDIR}/hpssTmp
mkdir -p ${hpssTmp}

cat > ${hpssTmp}/job_hpss_${CDATE}.sh << EOF
#!/bin/bash --login
#SBATCH -J hpss-${CDATE}
#SBATCH -A ${HPSS_ACCOUNT}
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-${CDATE}-out.txt
#SBATCH -e ./hpss-${CDATE}-err.txt

module load hpss

expName=${PSLOT}
dataDir=${ROTDIR}
tmpDir=${ROTDIR}/hpssTmp
bakupDir=${ROTDIR}/../dr-data-backup
logDir=${ROTDIR}/logs
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanal=${NMEM_AERO}
cycN=\`\${incdate} -12 ${CDATE}\`
cycN1=\`\${incdate} 6 \${cycN}\`

mkdir -p \${tmpDir}
mkdir -p \${bakupDir}

#hpssDir=/ESRL/BMC/wrf-chem/5year/Bo.Huang/JEDIFV3-AERODA/expRuns/
hpssDir=${HPSSDIR}
hpssExpDir=\${hpssDir}/\${expName}/dr-data/
hsi "mkdir -p \${hpssExpDir}"

echo \${cycN}
cycY=\`echo \${cycN} | cut -c 1-4\`
cycM=\`echo \${cycN} | cut -c 5-6\`
cycD=\`echo \${cycN} | cut -c 7-8\`
cycH=\`echo \${cycN} | cut -c 9-10\`
cycYMD=\`echo \${cycN} | cut -c 1-8\`

echo \${cycN1}
cyc1Y=\`echo \${cycN1} | cut -c 1-4\`
cyc1M=\`echo \${cycN1} | cut -c 5-6\`
cyc1D=\`echo \${cycN1} | cut -c 7-8\`
cyc1H=\`echo \${cycN1} | cut -c 9-10\`
cyc1YMD=\`echo \${cycN1} | cut -c 1-8\`
cyc1prefix=\${cyc1YMD}.\${cyc1H}0000

cntlGDAS=\${dataDir}/gdas.\${cycYMD}/\${cycH}/

if [ -s \${cntlGDAS} ]; then
### Copy the logfiles
    /bin/cp -r \${logDir}/\${cycN} \${cntlGDAS}/\${cycN}_log

### Clean unnecessary cntl files
    #/bin/rm -rf \${cntlGDAS}/gdas.t??z.atmf???.nc
    #/bin/rm -rf \${cntlGDAS}/gdas.t??z.sfcf???.nc
    /bin/rm -rf \${cntlGDAS}/gdas.t??z.logf???.txt
    #/bin/rm -rf \${cntlGDAS}/fireemi

### Backup cntl data
    cntlBakup=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/
    mkdir -p \${cntlBakup}
    /bin/cp \${cntlGDAS}/RESTART/*.fv_aod_* \${cntlBakup}/
    #/bin/cp \${cntlGDAS}/RESTART/*.fv_core.* \${cntlBakup}/
    /bin/cp \${cntlGDAS}/obs/* \${cntlBakup}/
    /bin/cp \${cntlGDAS}/RESTART/\${cyc1prefix}.coupler.res.* \${cntlBakup}/
    /bin/cp \${cntlGDAS}/RESTART/\${cyc1prefix}.fv_tracer.* \${cntlBakup}/
    /bin/cp \${cntlGDAS}/RESTART/\${cyc1prefix}.fv_core.* \${cntlBakup}/

    if [ \$? != '0' ]; then
       echo "Copy Control gdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
       exit \$?
    fi
    

### Start EnKF
    enkfGDAS=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/

### Delite unnecessary ens files
    /bin/rm -rf \${enkfGDAS}/efcs.grp??
    #/bin/rm -rf \${enkfGDAS}/fireemi

    enkfGDAS_Mean=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/ensmean
    enkfBakup_Mean=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/ensmean

    mkdir -p \${enkfBakup_Mean}
    /bin/cp \${enkfGDAS_Mean}/RESTART/*.fv_aod_* \${enkfBakup_Mean}/
    #/bin/cp \${enkfGDAS_Mean}/RESTART/*.fv_core.* \${enkfBakup_Mean}/
    /bin/cp \${enkfGDAS_Mean}/obs/* \${enkfBakup_Mean}/
    /bin/cp \${enkfGDAS_Mean}/RESTART/\${cyc1prefix}.coupler.res.* \${enkfBakup_Mean}/
    /bin/cp \${enkfGDAS_Mean}/RESTART/\${cyc1prefix}.fv_tracer.* \${enkfBakup_Mean}/
    /bin/cp \${enkfGDAS_Mean}/RESTART/\${cyc1prefix}.fv_core.* \${enkfBakup_Mean}/

    ianal=1
    while [ \${ianal} -le \${nanal} ]; do
       memStr=mem\`printf %03i \$ianal\`

       enkfGDAS_Mem=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/\${memStr}
       enkfBakup_Mem=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/\${memStr}

       ### clean uncessary mem files
       #/bin/rm -r \${enkfGDAS_Mem}/gdas.t??z.atmf???.nc
       #/bin/rm -r \${enkfGDAS_Mem}/gdas.t??z.sfcf???.nc
       /bin/rm -r \${enkfGDAS_Mem}/gdas.t??z.logf???.txt

       ### back mem data
       mkdir -p \${enkfBakup_Mem}
       /bin/cp \${enkfGDAS_Mem}/RESTART/*.fv_aod_* \${enkfBakup_Mem}
       /bin/cp \${enkfGDAS_Mem}/obs/* \${enkfBakup_Mem}
       #/bin/cp \${enkfGDAS_Mem}/RESTART/*.fv_tracer.* \${enkfBakup_Mem}

       ianal=\$[\$ianal+1]

    done

    if [ \$? != '0' ]; then
       echo "Copy EnKF enkfgdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
       exit \$?
    fi

    #htar -cv -f \${hpssExpDir}/gdas.\${cycN}.tar \${cntlGDAS}
    cd \${cntlGDAS}
    htar -cv -f \${hpssExpDir}/gdas.\${cycN}.tar *
    #hsi ls -l \${hpssExpDir}/gdas.\${cycN}.tar
    stat=\$?
    if [ \${stat} != '0' ]; then
       echo "HTAR failed at gdas.\${cycN}  and exit at error code \${stat}"
	exit \${stat}
    else
       echo "HTAR at gdas.\${cycN} completed !"
       /bin/rm -rf  \${cntlGDAS}   #./gdas.\${cycN}
    fi

    #htar -cv -f \${hpssExpDir}/enkfgdas.\${cycN}.tar \${enkfGDAS}
    cd \${enkfGDAS}
    htar -cv -f \${hpssExpDir}/enkfgdas.\${cycN}.tar *
    #hsi ls -l \${hpssExpDir}/enkfgdas.\${cycN}.tar
    stat=\$?
    echo \${stat}
    if [ \${stat} != '0' ]; then
       echo "HTAR failed at enkfgdas.\${cycN}  and exit at error code \${stat}"
    	exit \${stat}
    else
       echo "HTAR at enkfgdas.\${cycN} completed !"
       /bin/rm -rf \${enkfGDAS}  #./enkfgdas.\${cycN}
    fi

    cycN=\`\${incdate} \${cycInc}  \${cycN}\`
fi
exit 0
EOF

cd ${hpssTmp}
sbatch job_hpss_${CDATE}.sh

exit $?

