#!/bin/bash

#----------------------------------------------------------------------
# Retrieve gfs v16 data.  v16 was officially implemented on 12 UTC
# March 22, 2021.  However, the way the switch over was done,
# the 'prod' v16 tarballs started March 21, 2021 06Z.
#----------------------------------------------------------------------

module load hpss

bundle=$1

set -x

cd $EXTRACT_DIR

NDATE1=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
date10_m6=`$NDATE1 -6 $yy$mm$dd$hh`

echo $date10_m6
yy_m6=$(echo $date10_m6 | cut -c1-4)
mm_m6=$(echo $date10_m6 | cut -c5-6)
dd_m6=$(echo $date10_m6 | cut -c7-8)
hh_m6=$(echo $date10_m6 | cut -c9-10)

#----------------------------------------------------------------------
# Get the atm and sfc 'anl' netcdf files from the gfs or gdas
# tarball.
#----------------------------------------------------------------------

if [ "$bundle" = "gdas" ] || [ "$bundle" = "gfs" ]; then

  if [ "$bundle" = "gdas" ] ; then
    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    #file=com_gfs_prod_gdas.${yy}${mm}${dd}_${hh}.gdas_nc.tar
    #file=com_gfs_v16.2_gdas.${yy}${mm}${dd}_${hh}.gdas_nc.tar
    file=com_gfs_v16.3_gdas.${yy}${mm}${dd}_${hh}.gdas_nc.tar
  else
    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_prod_gfs.${yy}${mm}${dd}_${hh}.gfs_nca.tar
  fi

  rm -f ./list.hires*
  touch ./list.hires3
#/apps/hpss/bin/htar -T 4 -tvf  $directory/$file > ./list.hires1
  htar -tvf  $directory/$file > ./list.hires1
  grep "anl.nc" ./list.hires1 > ./list.hires2
  while read -r line
  do 
    echo ${line##*' '} >> ./list.hires3
  done < "./list.hires2"

#/apps/hpss/bin/htar -T 4 -xvf $directory/$file -L ./list.hires3
  htar -xvf $directory/$file -L ./list.hires3
  rc=$?
  [ $rc != 0 ] && exit $rc

  rm -f ./list.hires*

#----------------------------------------------------------------------
# Get the 'abias' and radstat files when processing 'gdas'.
#----------------------------------------------------------------------

  #if [ "$bundle" = "gdas" ] ; then
  if [ "$bundle" = "gdas1" ] ; then

    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_prod_gdas.${yy}${mm}${dd}_${hh}.gdas_restart.tar

    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias_air
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias_int
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias_pc
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.radstat
    rc=$?
    [ $rc != 0 ] && exit $rc

  fi

#----------------------------------------------------------------------
# Get the enkf netcdf history files.  They are not saved for the
# current cycle.  So get the 6-hr forecast files from the
# previous cycle.
#----------------------------------------------------------------------

else

  group=$bundle

  directory=/NCEPPROD/hpssprod/runhistory/5year/rh${yy_m6}/${yy_m6}${mm_m6}/${yy_m6}${mm_m6}${dd_m6}
  #file=com_gfs_prod_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_${group}.tar
  #file=com_gfs_v16.2_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_${group}.tar
  file=com_gfs_v16.3_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_${group}.tar

  rm -f ./list*.${group}
  htar  -tvf  $directory/$file > ./list1.${group}
  
  grep "006.nc" ./list1.${group} > ./list2.${group}
  while read -r line
  do 
    echo ${line##*' '} >> ./list3.${group}
  done < "./list2.${group}"
  htar  -xvf $directory/$file  -L ./list3.${group}
  rc=$?
  [ $rc != 0 ] && exit $rc
  rm -f ./list*.${group}

  directory_re=/NCEPPROD/hpssprod/runhistory/rh${yy_m6}/${yy_m6}${mm_m6}/${yy_m6}${mm_m6}${dd_m6}
  #file_re=com_gfs_v16.2_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_restart_${group}.tar
  file_re=com_gfs_v16.3_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_restart_${group}.tar

  rm -f ./list_re*.${group}
  htar  -tvf  $directory_re/$file_re > ./list_re1.${group}
  grep "ratminc.nc" ./list_re1.${group} > ./list_re2.${group}
  while read -r line
  do 
    echo ${line##*' '} >> ./list_re3.${group}
  done < "./list_re2.${group}"
  htar  -xvf $directory_re/$file_re  -L ./list_re3.${group}
  rc=$?
  [ $rc != 0 ] && exit $rc
  rm -f ./list_re*.${group}

fi

set +x
echo DATA PULL FOR $bundle DONE

exit 0
