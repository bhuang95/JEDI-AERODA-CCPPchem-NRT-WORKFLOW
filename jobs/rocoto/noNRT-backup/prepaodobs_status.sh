#!/bin/bash 
OBSDIR_NESDIS=${OBSDIR_NESDIS:-"/scratch2/BMC/public/data/sat/nesdis/viirs/aod/conus/"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
CDATE=$1
CYCINTHR=$2
AODSAT=$3

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
STARTYMDH=${STARTYY}${STARTMM}${STARTDD}${STARTHH}

ENDYY=`echo "${ENDOBS}" | cut -c1-4`
ENDMM=`echo "${ENDOBS}" | cut -c5-6`
ENDDD=`echo "${ENDOBS}" | cut -c7-8`
ENDHH=`echo "${ENDOBS}" | cut -c9-10`
ENDYMD=${ENDYY}${ENDMM}${ENDDD}
ENDYMDH=${ENDYY}${ENDMM}${ENDDD}${ENDHH}

echo ${STARTYMDH}
echo ${ENDYMDH}

for sat in ${AODSAT}; do
    if ( ! ls ${OBSDIR_NESDIS}/*_${sat}_s${STARTYMDH}*_*.nc ); then
        echo "Too early and start files do not exist. Waiting"
        exit 1
    fi

    if ( ! ls ${OBSDIR_NESDIS}/*_${sat}_*_e${ENDYMDH}*_*.nc ); then
        echo "Too early and end files do not exist. Waiting"
        exit 1
    fi
done

s1=`ls -ta1 ${OBSDIR_NESDIS}/*_s${STARTYMDH}*_*.nc | sort -u`
e1=`ls -ta1 ${OBSDIR_NESDIS}/*_e${ENDYMDH}*_*.nc | sort -u`

sleep 300

s2=`ls -ta1 ${OBSDIR_NESDIS}/*_s${STARTYMDH}*_*.nc | sort -u`
e2=`ls -ta1 ${OBSDIR_NESDIS}/*_e${ENDYMDH}*_*.nc | sort -u`


if [[ ${s1} == ${s2} && ${e1} == ${e2} ]] ; then
   echo "File transfer completed. Start prepaodobs task"
   exit 0
else
   echo "File transfer in progress. Waiting..."
   exit 1
fi


exit $?
