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
obsDir=${OBSDIR}
obsDir_VIIRS=${OBSDIR_VIIRS}
tmpDir=${ROTDIR}/hpssTmp
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
nanal=${NMEM_AERO}
cycN=\`\${incdate} -6 ${CDATE}\`
bakupDir=\${tmpDir}/dr-data-backup-\${cycN}
#cycN=${CDATE}
cycN1=\`\${incdate} -6 \${cycN}\`

mkdir -p \${tmpDir}

hpssDir=${HPSSDIR}
hpssExpDir=\${hpssDir}/\${expName}/dr-data-backup/
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

### Backup cntl data
    cntlBakup=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/
    mkdir -p \${cntlBakup}/obs
    mkdir -p \${cntlBakup}/RESTART
    /bin/cp -r \${cntlGDAS}/obs/* \${cntlBakup}/obs/
    /bin/cp -r \${cntlGDAS}/RESTART/*.fv_aod_* \${cntlBakup}/RESTART/

    if [ \$? != '0' ]; then
       echo "Copy Control gdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
       echo "\${cycYMD}\${cycH}" >> \${tmpDir}/HPSS_FAILED.record
       exit \$?
    fi
    
### Tar preprocessed obs files, sfc data and gbbepx
    obsTmpDir=\${bakupDir}/AODobs
    mkdir -p \${obsTmpDir}
    cp -r \${obsDir}/\${cycN}/* \${obsTmpDir}/
    cp -r \${obsDir_VIIRS}/\${cycN}/* \${obsTmpDir}/

    if [ \$? != '0' ]; then
       echo "Copy AODobs.\${cycYMD}\${cycH} failed and exit at error code \$?"
       echo "\${cycYMD}\${cycH}" >> \${tmpDir}/HPSS_FAILED.record
       exit \$?
    fi

    cd \${bakupDir}
    htar -cv -f \${hpssExpDir}/dr-data-backup.\${cycN}.tar *
    stat=\$?
    echo \${stat}
    if [ \${stat} != '0' ]; then
       echo "HTAR failed at prepdata.\${cycN}  and exit at error code \${stat}"
       echo "\${cycYMD}\${cycH}" >> \${tmpDir}/HPSS_FAILED.record
    	exit \${stat}
    else
       echo "HTAR at prepdata.\${cycN} completed !"
       echo "YES"  \${tmpDir}/hpss-\${cycN}.check
       /bin/rm -rf \${bakupDir}
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

