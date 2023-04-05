#!/bin/bash

DIR1=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/C96
DIR2=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data

echo "Change permission for ${DIR1}"
chmod -R 777 ${DIR1}/*
echo "Change permission for ${DIR2}"
chmod -R 777 ${DIR2}/*
