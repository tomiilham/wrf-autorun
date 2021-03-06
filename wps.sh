#!/bin/bash
#
# Copyright (C) Yagnesh Raghava Yakkala. http://yagnesh.org
#    File: wps.sh
# Created: Monday, May  2 2011
# Licence: GPL v3 or later.

# Description:
# run the wps program automatically

# Vtables
fnl_vtable_name=Vtable.GFS
sst_vtable_name=Vtable.SST
namelist=namelist.wps

exe_suffix=""
export  LD_LIBRARY_PATH=/home/yagnesh/wrf/intel/lib/:$LD_LIBRARY_PATH

geogrid_exe="geogrid.exe""$exe_suffix"
ungrib_exe="ungrib.exe""$exe_suffix"
metgrid_exe="metgrid.exe""$exe_suffix"

envf_name=dirnames.sh
cd `pwd`                        # go to the working directory possibly WPS dir

# make sure env file is there
if [ ! ./$envf_name ]; then
    echo "No ENV file"
    exit 24
else
    . ./$envf_name
fi

error_args=64
error_exe=128
minargs=1
arg=$1

function usage() {
    echo USAGE: " $1 <geo|ungrib|met|all|clean>"
}

# teach usage
if [ $# -lt $minargs ]
then
    echo "${#} arguments."
    usage $0
    exit $error_args;
fi


#-----------------------------------------------------------------------
function message() {
    echo  "$@"
    echo ''
}

function run_geogrid() {
    message running: GEOGRID.EXE
    $wrf_bin_dir/${geogrid_exe} | tee log.geogrid
    check_error $0 ${geogrid_exe}
}

function run_ungrib () {
    # run_ungrib <Vtable.???> <data dir to link> <data_prefix to link>
    ln -sf $tbls_dir/$1 Vtable
    message linking data from $2
    $wrf_bin_dir/link_grib.csh $2/$3 &&
        message running: ${ungrib_exe} &&
        $wrf_bin_dir/${ungrib_exe} | tee log.ungrib
    check_error $0 ${ungrib_exe}
}

function run_metgrid() {
    $wrf_bin_dir/${metgrid_exe} | tee log.metgrid
    check_error $0 ${metgrid_exe}
}

function check_error() {
    if [ ! $0 == $1 ]; then
        echo Something has gone wrong: $1;
        exit $error_exe
    fi
}
#-----------------------------------------------------------------------

case $arg in

    # geogrid
    geo*|GE*|Geo* )
        # name list options
        # opt_output_from_geogrid_path=${opt_output_from_geogrid_path:`pwd`}
        echo "opt_output_from_geogrid_path::---->" $opt_output_from_geogrid_path
        if [ `ls $opt_output_from_geogrid_path/geo_* | wc -l` == 0 ]; then
            change-option.pl $namelist opt_output_from_geogrid_path \'$opt_output_from_geogrid_path\' &&
                run_geogrid
        else
            message skipping geogrid.exe
        fi
        ;;


    # ungrib
    ung*|Ung*|UNG* )
        # FNL
        prefix=\'FILE\'
        interval_seconds=21600
        data_prefix=fnl
        if [ `ls FILE* | wc -l` == 0  ]; then
            change-option.pl  $namelist prefix $prefix &&
                change-option.pl $namelist interval_seconds $interval_seconds &&
                run_ungrib $fnl_vtable_name $fnl_dir $data_prefix
        else
            message skipping ungrib for FNL DATA..
        fi

        # SST
        prefix=\'SST\'
        interval_seconds=86400
        data_prefix=rtg
        if [  `ls SST* | wc -l` == 0 ] ; then
            change-option.pl  $namelist prefix $prefix &&
                change-option.pl  $namelist interval_seconds $interval_seconds &&
                run_ungrib $sst_vtable_name $sst_dir $data_prefix
        else
            message skipping ungrib for SST DATA..
        fi
        ;;

    # metgrid
    met*|Met*|MET* )
        interval_seconds=21600
        if [  `ls met_em* | wc -l` == 0 ] ; then
            change-option.pl $namelist interval_seconds $interval_seconds &&
                run_metgrid
        else
            message It seems, you have INPUT data.. skipping..
        fi
        ;;

    clean*|CLEAN*|cle )
        rm -if met_em.*
        rm -if FILE*
        rm -if SST*
        rm -if geo_em*
        rm -if PFILE*
        rm -if namelist.wps.1*
        rm -if GRIBFILE.*

        ;;

    All*|ALL*|all* )
        wps.sh geo
        wps.sh ungrib
        wps.sh met
        ;;

    * )
        usage $0
        ;;
esac
#-----------------------------------------------------------------------
exit 0;

# wps.sh ends here
