#!/usr/bin/env bash

system=$1
canal_dir=$2
#analysis_dir=$3
analysis_dir=/home/mdmannin/analysis/canal
cd $canal_dir

move_series_to_central_dir(){
for param in ydisp xdisp twist tip tilt tbend stretch stagger slide shift shear roll rise propel opening minw mind majw majd inclin h-twi h-ris buckle ax-bend; do
    # Create subdirectory if necessary, and move files.
    if [[ ! -d ${analysis_dir}/${param} ]]; then
        mkdir ${analysis_dir}/${param}
    fi
    mv *${param}.ser ${analysis_dir}/${param}/${system}.${param}.ser
done
}

copy_snapshot_info(){

curves_output_prefix=$1
target_dir=$2

# Make directory
if [[ ! -d ${analysis_dir}/${target_dir} ]]; then
    mkdir ${analysis_dir}/${target_dir}
fi

mv *.pdb ${analysis_dir}/${target_dir}

#for suffix in ".lis" ".cda" ".cdi" ".afr"; do
}

move_series_to_central_dir

cd ..