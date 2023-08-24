#!/usr/bin/env scripts

local system=$1
local canal_dir=$2
local source_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
analysis_dir=$(cd ${source_dir} && cd ..; pwd)
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

# Issue: What is this supposed to do?
copy_snapshot_info(){

  curves_output_prefix=$1
  target_dir=$2
  if [[ ! -d ${analysis_dir}/${target_dir} ]]; then
      mkdir ${analysis_dir}/${target_dir}
  fi

  mv *.pdb ${analysis_dir}/${target_dir}
}

move_series_to_central_dir