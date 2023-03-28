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
gbbDir=${GBBDIR}
icsDir=${ICSDIR}
obsDir=${OBSDIR}
caseCntl=${CASE_CNTL}
caseEnkf=${CASE_ENKF}
gbbShift=${GBBEPx_SHIFT}
gbbShiftHr=${GBBEPx_SHIFT_HR}
tmpDir=${ROTDIR}/hpssTmp
bakupDir=${ROTDIR}/../dr-data-backup
logDir=${ROTDIR}/logs
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanal=${NMEM_AERO}
cycN=\`\${incdate} -6 ${CDATE}\`
#cycN=${CDATE}
cycN1=\`\${incdate} 6 \${cycN}\`
if [ \${gbbShift} == "TRUE" ]; then
    cycGBB=\`\${incdate} \${gbbShiftHr} \${cycN}\`
else
    cycGBB=\${cycN}
fi

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

echo \${cycGBB}
cycGBBY=\`echo \${cycGBB} | cut -c 1-4\`
cycGBBM=\`echo \${cycGBB} | cut -c 5-6\`
cycGBBD=\`echo \${cycGBB} | cut -c 7-8\`
cycGBBH=\`echo \${cycGBB} | cut -c 9-10\`
cycGBBYMD=\`echo \${cycGBB} | cut -c 1-8\`
cycGBBprefix=\${cycGBBYMD}.\${cycGBBH}0000

cntlGDAS=\${dataDir}/gdas.\${cycYMD}/\${cycH}/

if [ -s \${cntlGDAS} ]; then
### Copy the logfiles
    /bin/cp -r \${logDir}/\${cycN} \${cntlGDAS}/\${cycN}_log

### Clean unnecessary cntl files
    /bin/rm -rf \${cntlGDAS}/gdas.t??z.logf???.txt

### Backup cntl data
    cntlBakup=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/

    mkdir -p \${cntlBakup}

    anaCntlTmpDir=\${cntlGDAS}/anaCntl
    mkdir -p \${anaCntlTmpDir}
    cp -r \${icsDir}/\${caseCntl}/gdas.\${cycYMD}/\${cycH}/RESTART/* \${anaCntlTmpDir}/

    gbbCntlTmpDir=\${cntlGDAS}/gbbCntl
    mkdir -p \${gbbCntlTmpDir}
    cp -r \${gbbDir}/\${caseCntl}/\${cycGBBYMD} \${gbbCntlTmpDir}/

    /bin/cp -r \${cntlGDAS}/* \${cntlBakup}/
    #/bin/cp \${cntlGDAS}/obs/* \${cntlBakup}/
    #/bin/cp \${cntlGDAS}/RESTART/*.fv_aod_* \${cntlBakup}/
    #/bin/cp \${cntlGDAS}/RESTART/\${cyc1prefix}.coupler.res.* \${cntlBakup}/
    #/bin/cp \${cntlGDAS}/RESTART/\${cyc1prefix}.fv_tracer.* \${cntlBakup}/
    #/bin/cp \${cntlGDAS}/RESTART/\${cyc1prefix}.fv_core.* \${cntlBakup}/

    if [ \$? != '0' ]; then
       echo "Copy Control gdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
       echo "\${cycYMD}\${cycH}" >> \${tmpDir}/HPSS_FAILED.record
       exit \$?
    fi
    
    #htar -cv -f \${hpssExpDir}/gdas.\${cycN}.tar \${cntlGDAS}
    cd \${cntlGDAS}
    htar -cv -f \${hpssExpDir}/gdas.\${cycN}.tar *
    #hsi ls -l \${hpssExpDir}/gdas.\${cycN}.tar
    stat=\$?
    if [ \${stat} != '0' ]; then
       echo "HTAR failed at gdas.\${cycN}  and exit at error code \${stat}"
       echo "\${cycYMD}\${cycH}" >> \${tmpDir}/HPSS_FAILED.record
	exit \${stat}
    else
       echo "HTAR at gdas.\${cycN} completed !"
       /bin/rm -rf  \${cntlGDAS}   #./gdas.\${cycN}
    fi

    cycN=\`\${incdate} \${cycInc}  \${cycN}\`
fi
exit 0
EOF

cd ${hpssTmp}
sbatch job_hpss_${CDATE}.sh
err=$?

sleep 60

exit ${err}

