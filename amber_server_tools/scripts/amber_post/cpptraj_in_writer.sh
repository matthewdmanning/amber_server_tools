#!/usr/bin/env scripts

# Create traj.in file and load prmtop/trajectories.

initialize_traj_in() {
path=$1
system=$2
trajin=$3



}
radius_of_gyration_multi(){


start_res=$1
stop_res=$2
trajin=$3
out_file=$4

printf "%s\n" "radgyr :${start_res}-${stop_res} out ${out_file} tensor" >> $trajin
}

radius_of_gyration_single(){

res_num=$1
trajin=$2
out_file=$3

printf "radgyr :%s out %s\n" "${res_num}" "${out_file}" >> ${trajin}
CLOSED

}

end_to_end_dist() {
path=$1
system=$2
start_res=$3
stop_res=$4
trajin=$5
out_file=$6
#image=$7

printf "distance :%s :%s out %s noimage\n" "${start_res}" "${stop_res}" "${out_file}" >> $trajin
}

energy_residue_pairwise(){
path=$1
system=$2
res1=$3
res2=$4
trajin=$5
out_file=$6

printf "energy :%s,%s out %s\n" "${res1}" "${res2}" "${out_file}" >> $trajin

}

drmsd_residue_combined(){
path=$1
system=$2
res_string=$3
ref=$4
trajin=$5
out_file=$6

### Need to find a way to determine whether ref frame or ref traj is passed in arguments/flags.
printf "drms :%s/n" "${res_string}"

}



printf "Search substring for folders...   "
read pattern
printf "Starting residue number....  "
read lig_start_res
printf "Last residue number...   "
read lig_stop_res
home_dir=`pwd`

for folder in *$pattern*/; do
    printf "${folder}"
    path=${folder/'/'}
    system=${path}
    traj_in_file="${system}.traj.in"
    ligand_radgyr_file="lig_radgyr.${system}.dat"
    cd $path




    traj_prefix="ions."
    traj_suffix=""
    parm_file=${traj_prefix}${system}.prmtop
    if [[ ! -f ${parm_file} ]]; then
        printf 'Parameter file %s not found. Moving on to next system.\n' "${parm_file}"
        continue
    fi
    printf "parm %s%s.%sprmtop\n" "${traj_prefix}" "${system}" "${traj_suffix}" > ${traj_in_file}

    printf "Search for trajectories: %s%s.md*.%snc.\n" "${traj_prefix}" "${system}" "${traj_suffix}"
    traj_start=0
    while [[ ! -f "${traj_prefix}${system}.md${traj_start}.${traj_suffix}nc" ]] && [[ ${traj_start} -lt 100 ]]; do
        #printf "${traj_prefix}${system}.md${traj_start}.${traj_suffix}nc\n"
        traj_start=$(( traj_start + 1 ))
    done
    if [[ ${traj_start} -eq 0 ]] || [[ ${traj_start} -eq 100 ]]; then
        printf "No trajectories found. Moving to next system.\n\n"
        cd ..
        continue
    fi
    printf "First trajectory found: %s.\n" "${traj_prefix}${system}.md${traj_start}.${traj_suffix}nc"
    traj_last=$(( traj_start + 0 ))
    while [[ -f "${traj_prefix}${system}.md${traj_last}.${traj_suffix}nc" ]]; do
        printf "trajin %s%s.md%s.%snc\n" "${traj_prefix}" "${system}" "${traj_last}" "${traj_suffix}" >> ${traj_in_file}
        traj_last=$(( traj_last + 1 ))
    done
    # Go back to last valid trajectory.
    traj_last=$(( traj_last - 1 ))
    printf "Trajectories %s-%s\n" "${traj_start}" "${traj_last}"



    #for residue in `seq ${lig_start_res} ${lig_stop_res}`; do
    #    radius_of_gyration_single "$residue" "$traj_in_file" "$ligand_radgyr_file"
    #done
    #np_radgyr_file="np_radgyr.${system}.dat"
    #radius_of_gyration_multi "$lig_start_res" "$lig_stop_res" "$traj_in_file" "$np_radgyr_file"
    #rna_radgyr_file="rna_radgyr.${system}.dat"

    #radius_of_gyration_multi "$lig_start_res" "$lig_stop_res" "$traj_in_file" "$rna_radgyr_file"


    #e2e_file_name=e2e.rna.${system}.md${traj_start}-${traj_last}.dat
    #end_to_end_dist "$path" "$system" "$lig_start_res" "$lig_stop_res" "${traj_in_file}" "${e2e_file_name}"

    nucleic_pairwise_name=energy.basepairs.${system}.md${traj_start}-${traj_last}.dat
    res1=${lig_start_res}
    res2=${lig_stop_res}
    while [[ ${res2} > ${res1} ]]; do
        energy_residue_pairwise "$path" "$system" "$res1" "$res2" "$traj_in_file" "$nucleic_pairwise_name"
        res1=$(( res1 + 1 ))
        res2=$(( res2 -1 ))
    done


    printf "run" >> ${traj_in_file}
    printf "quit" >> ${traj_in_file}
    cpptraj -i ${traj_in_file} C6OH,
    mv $nucleic_pairwise_name ~/analysis/

    cd ${home_dir}

done