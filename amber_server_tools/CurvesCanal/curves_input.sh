#!/bin/bash



overwrite_traj=false

source ~/PycharmProjects/nanorodbuilder/inFiles/folder_methods.sh

write_curves_input(){
    local path=$1
    local system=$2
    local residue_start=$3
    local residue_stop=$4
    local nucleic_type=$5
    local parm_name=$6
    local traj_name=$7
    local ions=${8:".f"}
    ions=".f"
    na_length=$(( $residue_stop - $residue_start ))
    if [ $(( $na_length % 2 )) -eq 0 ]; then
        echo "Length of NA chain is odd. Not running..."
        break
    fi

    local second_start=$(( na_length/2 + residue_start + 1 ))
    local first_stop=$(( second_start - 1))

    local output_prefix="curves_${nucleic_type}"
    #echo `ls -ld ${path}/${output_prefix}*`

printf "Running Curves+ analysis on %s.\n" "${system}"

cd $path
curves_input="./curves.sh"
curves_lib="/home/mdmannin/curves+/standard"
traj_path="./"

cat <<EOT > ${curves_input}
rm ${output_prefix}*
/home/mdmannin/curves+/Cur+ <<!
 &inp ftop=${parm_name}, file=${traj_name}, lis=${output_prefix}, ions=${ions}, axfrm=.t, fit=.t, lib=${curves_lib},
&end
2 1 -1 0 0
${residue_start}: ${first_stop}
${residue_stop}: ${second_start}
!
EOT

printf "Curves input file given below:\n"
more ${curves_input}
chmod +x ${curves_input}
source ${curves_input}

cd ..
}

write_canal_input(){
    local path=$1
    local system=$2
    local residue_start=$3
    local residue_stop=$4
    local nucleic_type=$5
    local parm_name=$6
    local traj_name=$7



rm test_ga.* test_ga_*.*
/Users/RL/Code/util/canal <<!
 &inp lis=test_ga,seq=GA,
 lev1=3,lev2=16,histo=.t., &end
 GGGA_spc GCGAGGGAGGGAGGGAGC
 GAAA_spc GCAAGAAAGAAAGAAAGC
!

}

write_curves_pdb(){
    local path=$1
    local system=$2
    local residue_start=$3
    local residue_stop=$4
    local nucleic_type=$5
    local pdb_name=$6
    local ions=${7:".f"}
    ions=".t"

    if [ $(( $na_length % 2 )) -eq 0 ]; then
        echo "Length of NA chain is odd. Not running..."
        break
    fi

    local second_start=$(( na_length/2 + residue_start + 1 ))
    local first_stop=$(( second_start - 1))

    local output_prefix="pdb+${nucleic_type}"
rm ${curves_input}
cat <<EOT > ${curves_input}
rm ${output_prefix}.*
/home/mdmannin/curves+/Cur+ <<!
 &inp file=${traj_name}, lis=${output_prefix}, ions=${ions}, axfrm=.t, fit=.t,
 lib=${curves_lib},
 &end
 2 1 -1 0 0
 ${residue_start}: ${first_stop}
 ${residue_stop}: ${second_start}
!
EOT

}
# Processes trajectory by stripping trajectory and leaving only specified range of residues.
prep_separate_traj(){

    local path=$1
    local system=$2
    local traj_start=$3
    local traj_stop=$4
    local residue_start=$5
    local residue_stop=$6
    local traj_prefix=$7
    local traj_suffix=$8
    local offset=$9
    local nucleic_type="$10"

    local trajin=cpptraj_curves_prep.in

    printf "Preparing trajectories for MD runs %s-%s.\n" "${traj_start}" "${traj_stop}"
    sleep 5
    # Set the GLOBAL variables for the prmtop and trj file names.
    input_parm="${path}/${traj_prefix}${system}.prmtop"
    nucleic_parm="${nucleic_type}.prmtop"
    nucleic_traj="${nucleic_type}.md${traj_start}-${traj_stop}.${offset}.trj"
    printf "Outputting AMBER trajectory: %s.\n\n" "${nucleic_traj}"
    sleep 5
    if [[ ! -f ${path}/${nucleic_traj} ]] || [[ "${overwrite_traj}" != "false" ]]; then
        if [[ -f ${path}/${nucleic_traj} ]]; then
            printf "Trajectory %s already exists. Overwriting.\n" "${nucleic_traj}"
        fi
        printf "parm %s\n" "${input_parm}" > ${trajin}
        for traj_num in `seq $traj_start $traj_stop`; do
            local input_traj=${traj_prefix}${system}.md${traj_num}.${traj_suffix}nc
            printf "trajin %s/%s 1 last %s\n" "${path}" "${input_traj}" "${offset}" >> ${trajin}
        done
        printf "image :%s\n" "${residue_start}" >> ${trajin}
        printf "strip !:%s-%s\n" "${residue_start}" "${residue_stop}" >> ${trajin}
        printf "parmwrite out %s/%s\n" "${path}" "${nucleic_parm}" >> ${trajin}
        printf "trajout %s/%s\n" "${path}" "${nucleic_traj}" >> ${trajin}
        printf "run\n" >> ${trajin}
        printf "quit\n" >> ${trajin}

        cpptraj -i ${trajin} | grep -v 'Could not determine atomic number from'
        #mv ${nucleic_traj} ${nucleic_traj/'crd'/'trj'}
    elif [[ -f ${path}/${nucleic_traj} ]]; then #&& [[ "${overwrite_traj}" == "false" ]]; then
        printf "Trajectory %s already exists. Not overwriting.\n" "${nucleic_traj}"

    fi
}

path(){
    local na_start=1
    local na_stop=80
    #local traj_offset=10
    #local traj_prefix=ions.
    #local traj_suffix=skip10.
    printf "Enter trajectory prefix (eg. ions. or strip.)\n"
        local traj_prefix
        read traj_prefix
    printf "Enter trajectory suffix (eg. skip10. )\n"
        local traj_suffix
        read traj_suffix
    printf "Enter frame offset to analyze every nth frame."
        local traj_offset
        read traj_offset
    if [[ ! ${traj_offset} -gt 0 ]]; then
        printf "Trajectory frame offset set to 1 by default. Original value was %s.\n" "${traj_offset}"
        traj_offset=1
    fi
    for folder in */; do
        if [ ${folder} == "ins/" ]; then
            echo "Inputs found. Skipping."
            continue
        fi
        local path=${folder/'/'}
        local system="$path"
        printf "Processing system: %s\n" "${system}"
        if [[ ${system} == "*rna*" ]]; then
            na_type="rna"
        elif [[ ${system} == "*dna*" ]]; then
            na_type="dna"
        else
            echo "Nucleic acid type not found in ${system}. Enter manually..."
            #read na_type
            na_type=rna
        fi
        printf "Using nucleic acid type: %s.\n" "${na_type}"
        #na_type=rna

        #trajectory_number_array = get_continuous_traj "$path" "$system" "ions" ""
        #local trajectory_number_array=(1 2 3 4 5 6 7)
        #echo ${trajectory_number_array[*]}
        #"${trajectory_number_array[0]}" "${trajectory_number_array[-1]}"
        ls ${path}/${traj_prefix}*.nc
        #printf "What is the index of the first trajectory?: \n"
        #read traj_start
        #printf "What is the index of the first trajectory?: \n"
        #read traj_last
        traj_start=0
        printf "Search for trajectories: %s/%s%s.md*.%snc.\n" "${path}" "${traj_prefix}" "${system}" "${traj_suffix}"
        while [[ ! -f "${path}/${traj_prefix}${system}.md${traj_start}.${traj_suffix}nc" ]] && [[ ${traj_start} -lt 100 ]]; do
            echo "${path}/${traj_prefix}${system}.md${traj_start}.${traj_suffix}nc"
            traj_start=$(( traj_start + 1 ))
        done
        if [[ ${traj_start} -eq 0 ]] || [[ ${traj_start} -eq 100 ]]; then
            printf "No trajectories found. Moving to next system."
            continue
        fi
        printf "First trajectory found: %s.\n" "${path}/${traj_prefix}${system}.md${traj_start}.${traj_suffix}nc"
        traj_last=$(( traj_start + 0 ))
        while [[ -f "${path}/${traj_prefix}${system}.md${traj_last}.${traj_suffix}nc" ]]; do
            traj_last=$(( traj_last + 1 ))
        done
        # Go back to last valid trajectory.
        traj_last=$(( traj_last - 1 ))
        echo ${traj_start} ${traj_last}
        #traj_start=3
        #traj_last=5
        prep_separate_traj "${path}" "${system}" "${traj_start}" "${traj_last}" "${na_start}" "${na_stop}" "${traj_prefix}" "${traj_suffix}" "${traj_offset}" "${na_type}"

        new_na_start=1
        new_na_stop=$(( na_stop - na_start + 1 ))
        write_curves_input "${path}" "${system}" "${new_na_start}" "${new_na_stop}" "${na_type}" "${nucleic_parm}" "${nucleic_traj}"
        source ~/PycharmProjects/nanorodbuilder/CurvesCanal/canal.sh
    done
}
run_type=$1
if [[ ! $run_type ]]; then
    printf "Select between path or here...\n"
    read run_type
fi
if [[ ${run_type} == "path" ]]; then
    path
#elif [[ ${run_type} == "here" ]]; then
#    here
fi

#### Nameslist Variables for curves+ input files
#CHARACTER (strings without quotes, maximum length 128 characters):
#file:  file name for input structure (.pdb and .mac extensions need not be given in input, use .trj for MD trajectories)
#ftop:  name (with extension) of file with topological data (AMBER format) for MD trajectory analysis
#lis: root file name for all output (.lis, .cda, .cdi, .cdl, .fra, _X.pdb, _B.pdb, _C.pdb)
#lib: root file name for base (_b.lib) and backbone (_s.lib) geometry files
#lig: name (.lig extension assumed) for reference geometry of ligand
#ibld: name (.cdi extension assumed) of ion coordinates for reconstruction
#sol: name of solute molecule in input .pdb file (or Amber topology file) to be analyzed if ions=.t.
#back (P): atom used to define backbone. Different backbone can use different atoms if necessary (e.g. P/C5* - a slash is used to separate input names).
####