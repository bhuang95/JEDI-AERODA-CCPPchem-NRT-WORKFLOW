#!/bin/bash 

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
#. $HOMEgfs/ush/load_fv3gfs_modules.sh


HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20210614/build/"}
METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasInc/"}
METDIR_WCOSS=${METDIR_WCOSS:-"/scratch1/BMC/chem-var/pagowski/junk_scp/wcoss/"}
CDATE=${CDATE:-"2021060900"}
CDUMP=${CDUMP:-"gdas"};
CYCINTHR=${CYCINTHR:-"6"}
CASE=${CASE_CNTL:-"C96"}
CASE_GDAS=${CASE_CNTL_GDAS:-"C768"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}


CASERES=`echo "$CASE" | tr '[:upper:]' '[:lower:]'`
CASERESC=$(echo $CASERES |cut -c2-5)
CASERESX=$((CASERESC+1))
CASERESY=$((CASERESC+1))

CASERES_GDAS=`echo "$CASE_GDAS" | tr '[:upper:]' '[:lower:]'`
CASERESC_GDAS=$(echo $CASERES_GDAS |cut -c2-5)
CASERESX_GDAS=$((CASERESC_GDAS+1))
CASERESY_GDAS=$((CASERESC_GDAS+1))

FIELDDIR=${HOMEjedi}/fv3-jedi/test/Data/fieldsets/
FV3DIR=${HOMEjedi}/fv3-jedi/test/Data/fv3files/
CONVERTEXEC=${HOMEjedi}/bin/fv3jedi_convertstate.x


NLN="/bin/ln -sf"

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepmetincrestart"
[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10

. /apps/lmod/lmod/init/bash
. ${HOMEjedi}/jedi_module_base.hera
status=$?
module list
[[ $status -ne 0 ]] && exit $status

RES=`echo $CASE | cut -c2-4`
YY=`echo "${CDATE}" | cut -c1-4`
MM=`echo "${CDATE}" | cut -c5-6`
DD=`echo "${CDATE}" | cut -c7-8`
HH=`echo "${CDATE}" | cut -c9-10`

REDATE=$(${NDATE} ${CYCINTHR} ${CDATE})
REYY=`echo "${RECDATE}" | cut -c1-4`
REMM=`echo "${RECDATE}" | cut -c5-6`
REDD=`echo "${RECDATE}" | cut -c7-8`
REHH=`echo "${RECDATE}" | cut -c9-10`
REDATESTR=${REYY}${REMM}${REDD}.${REHH}0000

METTARFILE=${METDIR_WCOSS}/${CDUMP}.${YY}${MM}${DD}${HH}.tar
METOUTDIR=${METDIR_NRT}/${CASE}/${CDUMP}.${YY}${MM}${DD}${HH}/
[[ ! -d ${METOUTDIR} ]] && mkdir -p ${METOUTDIR}


echo "Untar Met file: ${METTARFILE}"
/bin/tar -xvf ${METTARFILE} --directory ${METOUTDIR}
status=$?
if [[ $status -ne 0 ]]; then
    echo "Untar Met file failed : ${METTARFILE}"
    exit $status
fi

/bin/mv ${METOUTDIR}/RESTART ${METOUTDIR}/RESTART-GDAS
mkdir -p ${METOUTDIR}/RESTART


# Link files
${NLN} ${FV3DIR}/fmsmpp.nml ${DATA}/fmsmpp.nml
${NLN} ${FV3DIR}/field_table ${DATA}/field_table
${NLN} ${FV3DIR}/akbk64.nc4 ${DATA}/akbk64.nc4
${NLN} ${FV3DIR}/akbk127.nc4 ${DATA}/akbk127.nc4
${NLN} ${FIELDDIR}/dynamics.yaml ${DATA}/dynamics.yaml
${NLN} ${FIELDDIR}/aerosols_gfs.yaml ${DATA}/aerosols_gfs.yaml
${NLN} ${FIELDDIR}/chemical_add_gfs.yaml ${DATA}/chemical_add_gfs.yaml
${NLN} ${CONVERTEXEC} ${DATA}/fv3jedi_convertstate.x


# create yaml file
cat << EOF > ${DATA}/fv3jedi_convertstate_gfs_aero.yaml
input geometry:
  nml_file_mpp: fmsmpp.nml
  trc_file: field_table
  akbk: akbk127.nc4
  layout: [1,1]
  io_layout: [1,1]
  npx: ${CASERESX_GDAS}
  npy: ${CASERESX_GDAS}
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: dynamics.yaml
    - fieldset: aerosols_gfs.yaml
    - fieldset: chemical_add_gfs.yaml
output geometry:
  trc_file: field_table
  akbk: akbk64.nc
  layout: [1,1]
  io_layout: [1,1]
  npx: ${CASERESX}
  npy: ${CASERESY}
  npz: 64
  ntiles: 6
  fieldsets:
    - fieldset: dynamics.yaml
    - fieldset: aerosols_gfs.yaml
states:
- input:
    filetype: gfs
    state variables: [u,v,ua,va,T,DELP,sphum,ice_wat,liq_wat,rainwat,
                      graupel,snowwat,cld_amt,o3mr,phis,
                      slmsk,sheleg,tsea,vtype,stype,vfrac,stc,smc,snwdph,
                      u_srf,v_srf,f10m,
                      so2,dms,msa,
                      sulf,bc1,bc2,oc1,oc2,
                      dust1,dust2,dust3,dust4,dust5,
                      seas1,seas2,seas3,seas4,seas5]
    datapath:${METOUTDIR}/RESTART-GDAS/ 
    filename_core: ${REDATESTR}.fv_core.res.nc
    filename_trcr: ${REDATESTR}.fv_tracer.res.nc
    filename_sfcd: ${REDATESTR}.sfc_data.nc
    filename_sfcw: ${REDATESTR}.fv_srf_wnd.res.nc
  output:
    filetype: gfs
    datapath: ${METOUTDIR}/RESTART/
    filename_core: ${REDATESTR}.fv_core.res.nc
    filename_trcr: ${REDATESTR}.fv_tracer.res.nc
    filename_sfcd: ${REDATESTR}.sfc_data.nc
    filename_sfcw: ${REDATESTR}.fv_srf_wnd.res.nc
EOF

echo "Run convertstate........"
export  LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20210614/build/lib"
#srun -n6 fv3jedi_convertstate.x fv3jedi_convertstate_gfs_aero.yaml
srun -n6 /scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/build/fv3-bundle/bin/fv3jedi_convertstate.x fv3jedi_convertstate_gfs_aero.yaml

err=$?

if [[ $err -eq 0 ]]; then
    echo "Running fv3jedi_convertstate.x is successful exit"
   # /bin/rm -rf $DATA
else
    echo "Running fv3jedi_convertstate.x failed and exit"
    exit 1
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err
