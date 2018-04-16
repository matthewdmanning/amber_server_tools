#!/usr/bin/env bash

thermo=$1
long_range=$2

input_path="${repo}/inFiles"

#cp /home/mdmannin/PycharmProjects/amber_server_tools/bash/run_amber.sh ./

get_inputs(){
    if [[ ! -d ins/ ]] ; then
        mkdir ins/
    fi
    cp ${input_path}/min.${long_range}.mdin ins/
    cp ${input_path}/heat.${thermo}.${long_range}.mdin ins/
    cp ${input_path}/equil1.${thermo}.${long_range}.mdin ins/
    cp ${input_path}/equil2.${thermo}.${long_range}.mdin ins/
    cp ${input_path}/md.${thermo}.${long_range}.mdin ins/
}

get_inputs