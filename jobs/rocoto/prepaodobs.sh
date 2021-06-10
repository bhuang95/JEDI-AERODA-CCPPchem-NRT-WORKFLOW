#!/bin/ksh -x

###############################################################
## Abstract:
## Create biomass burning emissions for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
#configs="base"
#for config in $configs; do
#    . $EXPDIR/config.${config}
#    status=$?
#    [[ $status -ne 0 ]] && exit $status
#done
###############################################################
STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodobs"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
OBSDIR_NESDIS=${OBSDIR_NESDIS:-"/scratch2/BMC/public/data/sat/nesdis/viirs/aod/conus/"}
OBSDIR_NRT=${OBSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/aodObs"}
AODTYPE=${AODTYPE:-"VIIRS"}
AODSAT=${AODSAT:-"j01 npp"}
CDATE=${CDATE:-"2001010100"}
CYCINTHRS=${CYCINTHRS:-"6"}
CASE=${CASE:-"C192"}
VIIRS2IODAEXEC=${VIIRS2IODAEXEC:-${HOMEgfs}/exec/convert_gbbepx.x}
VIIRS2IODAEXEC=/scratch2/BMC/wrfruc/Samuel.Trahan/viirs-thinning/mmapp_2018_src_omp/exec/viirs2ioda.x
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

FV3GRID=${HOMEgfs}/fix/fix_fv3/${CASE}
AODOUTDIR=${OBSDIR_NRT}-${AODTYPE}-${CASE}/${CDATE}
[[ ! -d ${AODOUTDIR} ]] && mkdir -p ${OUTDIR}

RES=`echo $CASE | cut -c2-4`
YY=`echo "${CDATE}" | cut -c1-4`
MM=`echo "${CDATE}" | cut -c5-6`
DD=`echo "${CDATE}" | cut -c7-8`
HH=`echo "${CDATE}" | cut -c9-10`

HALFCYCLE=$(( CYCINTHR/2 ))
STARTOBS=$(${NDATE} -${HALFCYCLE} ${CDATE})
ENDOBS=$(${NDATE} ${HALFCYCLE} ${CDATE})

STARTYY=`echo "${STARTOBS}" | cut -c1-4`
STARTMM=`echo "${STARTOBS}" | cut -c5-6`
STARTDD=`echo "${STARTOBS}" | cut -c7-8`
STARTHH=`echo "${STARTOBS}" | cut -c9-10`
STARTYMD=${STARTYY}${STARTMM}${STARTDD}
STARTYMDHMS=${STARTYY}${STARTMM}${STARTDD}${STARTHH}0000

ENDYY=`echo "${ENDOBS}" | cut -c1-4`
EMDMM=`echo "${ENDOBS}" | cut -c5-6`
EMDDD=`echo "${ENDOBS}" | cut -c7-8`
EMDHH=`echo "${ENDOBS}" | cut -c9-10`
EMDYMD=${ENDYY}${ENDMM}${ENDDD}
EMDYMDHMS=${ENDYY}${ENDMM}${ENDDD}${ENDHH}0000

for sat in ${AODSAT}; do
    declare -a usefiles # usefiles is now an array
    usefiles=() # clear the list of files
    for f in $( ls -1 ${OBSDIR_NESDIS}/*${sat}*${STARTYMD}*.nc ${OBSDIR_NESDIS}/*${sat}*${ENDYMD}*.nc | sort -u ) ; do
        # Match the _s(number) start time and make sure it is after the time of interest
	#if ! [[ $f =~ ^.*_${sat}_s([0-9]{14}) ]] || ! (( BASH_REMATCH[1] >= STARTYMDHMS )) ; then
	#if ! [[ $f =~ ^.*_s([0-9]{14}) ]] || ! (( BASH_REMATCH[1] >= STARTYMDHMS )) ; then
	if ! [[ $f =~ ^.*_s([0-9]{14}) ]] || ! (( BASH_REMATCH[1] >= STARTYMDHMS )) ; then
            echo "Skip; too early: $f"
        # Match the _e(number) end time and make sure it is after the time of interest
        #elif ! [[ $f =~ ^.*_${sat}*_e([0-9]{14}) ]] || ! (( BASH_REMATCH[1] <= ENDYMDHMS )) ; then
        elif ! [[ $f =~ ^.*_e([0-9]{14}) ]] || ! (( BASH_REMATCH[1] <= ENDYMDHMS )) ; then
            echo "Skip; too late:  $f"
        else
            echo "Using this file: $f"
            usefiles+=("$f") # Append the file to the usefiles array
        fi
    
         # Make sure we found some files.
         echo "Found ${#usefiles[@]} files between $STARTOBS and $ENDOBS."
         if ! (( ${#usefiles[@]} > 0 )) ; then
             echo "Error: no files found for specified time range in ${OBSDIR_NESDIS}" 1>&2
    	 exit 1
         fi
    done
    
    # Prepare the list of commands to run.
    [[ ! -e cmdfile ]] && rm -rf cmdfile
    cat /dev/null > cmdfile
    file_count=0
    for f in "${usefiles[@]}" ; do
        fout=$( basename "$f" )
        echo "${VIIRS2IODAEXEC}" "${CDATE}" "$FV3GRID" "$f" "$fout" >> cmdfile
        file_count=$(( file_count + 1 ))
    done
    
    # Run many tasks in parallel via mpiserial.
    mpiserial_flags='-m '
    echo "Now running executable ${VIIRS2IODAEXEC}"
    if ( ! srun -l mpiserial $mpiserial_flags cmdfile ) ; then
        echo "At least one of the files failed. See prior logs for details." 1>&2
        exit 1
    fi
    
    # Make sure all files were created.
    no_output=0
    success=0
    for f in "${usefiles[@]}" ; do
        fout=$( basename "$f" )
        if [[ -s "$fout" ]] ; then
            success=$(( success + 1 ))
        else
            no_output=$(( no_output + 1 ))
            echo "Missing output file: $fout"
        fi
    done
    
    if [[ "$success" -eq 0 ]] ; then
        echo "Error: no files were output in this analysis cycle. Perhaps there are no obs at this time?" 1>&2
            exit 1
    fi
    if [[ "$success" -ne "${#usefiles[@]}" ]] ; then
        echo "In analysis cycle ${CDATE}, only $success of ${#usefiles[@]} files were output."
        echo "Usually this means some files had no valid obs. See prior messages for details."
    else
        echo "In analysis cycle ${CDATE}, all $success of ${#usefiles[@]} files were output."
    fi
    
    # Merge the files.
    FINALFILE="${AODTYPE}_AOD_${sat}.${CDATE}.nc"
    echo Merging files now...
    if ( ! ncrcat -O *.nc "${FINALFILE}" ) ; then
        echo "Error: ncrcat returned non-zero exit status" 1>&2
        exit 1
    fi
    
    # Make sure they really were merged.
    if [[ ! -s "$FINALFILE" ]] ; then
        echo "Error: ncrcat did not create $FINALFILE." 1>&2
        exit 1
    fi
done
    
err=0    
#if [[ $err -eq 0 ]]; then
#    /bin/rm -rf $DATA
#fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
