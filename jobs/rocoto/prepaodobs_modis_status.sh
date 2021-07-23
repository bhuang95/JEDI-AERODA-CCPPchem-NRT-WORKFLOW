#!/bin/bash 
OBSDIR_MODIS_NASA=${OBSDIR_MODIS_NASA:-"/scratch2/BMC/public/data/sat/nasa/modis/aerosol/"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
CDATE=$1 #"2021072006" #$1
CYCINTHR=$2 #"6" #$2
#AODSAT=$3
AODSAT="MYD04_L2 MOD04_L2"
echo ${AODSAT}

YY=`echo "${CDATE}" | cut -c1-4`
MM=`echo "${CDATE}" | cut -c5-6`
DD=`echo "${CDATE}" | cut -c7-8`
HH=`echo "${CDATE}" | cut -c9-10`

HALFCYCLE=$(( CYCINTHR/2 ))
HALFCYCLEp3=$(( HALFCYCLE+3 ))
STARTOBS=$(${NDATE} -${HALFCYCLE} ${CDATE})
#ENDOBS=$(${NDATE} ${HALFCYCLEm1} ${CDATE})
ENDOBS=$(${NDATE} ${HALFCYCLEp3} ${CDATE})

STARTYY=`echo "${STARTOBS}" | cut -c1-4`
STARTMM=`echo "${STARTOBS}" | cut -c5-6`
STARTDD=`echo "${STARTOBS}" | cut -c7-8`
STARTHH=`echo "${STARTOBS}" | cut -c9-10`
STARTYMD=${STARTYY}${STARTMM}${STARTDD}
STARTMD_JULIAN=`date -d ${STARTYMD} +%j`
STARTYMDH_JULIAN=A${STARTYY}${STARTMD_JULIAN}.${STARTHH}

ENDYY=`echo "${ENDOBS}" | cut -c1-4`
ENDMM=`echo "${ENDOBS}" | cut -c5-6`
ENDDD=`echo "${ENDOBS}" | cut -c7-8`
ENDHH=`echo "${ENDOBS}" | cut -c9-10`
ENDYMD=${ENDYY}${ENDMM}${ENDDD}
ENDYMDH=${ENDYY}${ENDMM}${ENDDD}${ENDHH}
ENDMD_JULIAN=`date -d ${ENDYMD} +%j`
ENDYMDH_JULIAN=A${ENDYY}${ENDMD_JULIAN}.${ENDHH}


echo ${STARTYMDH_JULIAN}
echo ${ENDYMDH_JULIAN}

for sat in ${AODSAT}; do
    #if ( ! ls ${OBSDIR_MODIS_NASA}/${sat}.${STARTYMDH_JULIAN}??.061.NRT.hdf ); then
    #    echo "Too early and start files do not exist. Waiting"
    #    exit 1
    #else
    #	echo "${OBSDIR_MODIS_NASA}/${sat}.${STARTYMDH_JULIAN}??.061.NRT.hdf is available!"
    #fi

    if ( ! ls ${OBSDIR_MODIS_NASA}/${sat}.${ENDYMDH_JULIAN}??.061.NRT.hdf ); then
        echo "Too early and end files do not exist. Waiting"
        exit 1
    else
	echo "${OBSDIR_MODIS_NASA}/${sat}.${ENDYMDH_JULIAN}??.061.NRT.hdf is available!"
    fi
done

exit $?
