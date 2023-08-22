#!/usr/bin/env scripts

# This script is designed to automate the setup and running of systems with different thermostat methods and coupling constants for use in uncertainty quantification and sensitivity analysis.

module load amber/16

coupling_loop(){

    restart_file="$1"
    file_clip=${restart_file/'.rst7'}
    group_sim_name=${file_clip/'.md'/'_md'}
    echo $group_sim_name
    for constant in ${couplings[@]}; do
        system="${group_sim_name}_${coupling_name}${constant}"
        system_dir="${base_parm_name}_${coupling_name}_${constant}/${system}"
        mkdir "$system_dir"
        cp ${restart_file} ${system_dir}/${group_sim_name}.rst7
        cp ${original_parm_file} ${system_dir}/${group_sim_name}.prmtop
    done
}

restart_loop(){

    for restart in ${base_parm_name}*md*.rst7; do
        if [[ -f ${restart} ]]; then
            coupling_loop "$restart"
        fi
    done
}


base_parm_name="$1"
original_parm_file="${base_parm_name}.prmtop"
coupling_name="tautp"
couplings=(1 2 3 4 5)
head_dir="./"
for constant in ${couplings[@]}; do
    new_dir="${base_parm_name}_${coupling_name}_${constant}"
    mkdir ${new_dir}
    cp "ins/" "${new_dir}" -r
    sed_string="s/${coupling_name}.*/${coupling_name}=${constant}#/g"
    echo $sed_string
    for input_file in "${new_dir}/ins/*in"; do
        sed -i "${sed_string}" ${input_file}
        grep ${coupling_name} ${input_file}
    done
done

restart_loop