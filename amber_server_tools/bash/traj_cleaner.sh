#!/usr/bin/env bash
module load amber

keep_frame=10
dormant_cutoff_seconds=600 # Criterion for deciding whether a trajectory is being written to by running sim (in seconds).
delete_old_traj="False"
write_protect="True"
max_md_num=200
solute_percent=2 # Minimum file size of stripped trajectory as percentage of original trajectory
skip_size_buffer=98 # Allows (100-x) undershoot of file size of solvent strip trajectory.

path_loop(){
search_pattern=$1
for path in *"$search_pattern"*/; do
    if [[ -d ${path} ]] && [[ ${path} != "ins/" ]]; then
        cd "${path}" || continue
        system=${path/'/'}
        #echo "${system}"
        if [[ -z ${serial} ]]; then
            traj_loop "$system" &
        else
            traj_loop "$system"
        fi
        cd ..
    fi
done
}


traj_loop(){
    system="$1"
    #while [[ $(ls -A | head -c1 | wc -c) -eq 0 ]]; do
    for md_num in $(seq 1 "$max_md_num"); do
        traj=${system}.md${md_num}.nc
        [[ ! -f ${traj} ]] && continue
        current_time=$(date +%s) #Gives echo time in seconds.
        modified_time=$(date +%s -r ${traj})
        dormant_time=$(( current_time - modified_time ))
        #printf "Time since %s was last modified %s ago.\n" "${traj}" "${dormant_time}"
        if [[ ${dormant_time} -gt ${dormant_cutoff_seconds} ]]; then
            printf "%s has not been modified for more than %s.\n" "${traj}" "${dormant_cutoff_seconds}"
            strip_traj "$traj" "$system"
        else
            printf "%s might still be active. It was last modified %s seconds ago. Going to next traj. \n" "${traj}" "${dormant_time}"
            continue
        fi
    done
}

strip_traj(){
    traj=$1
    system=$2
    trimname=${traj%'.nc'}
    skipname="${trimname}.skip${keep_frame}.nc"
    strip_name="ions.${traj}"
    trajin="compress.${system}.in"
    if [[ -f "$skipname" ]]; then
        printf "Skipped frame trajectory already exists. %s\n" "${skipname}"
    fi
    if [[ -f "$strip_name" ]]; then
        printf "Stripped trajectory already exists. %s\n" "$strip_name"
    fi
    if [[ ${dormant_time} -gt 0 ]]; then
        echo "This traj: ${traj}"
        echo "parm ${system}.prmtop" > $trajin
        echo "trajin ${traj}" >> $trajin
        echo ${skipname}
        echo "trajout ${skipname} offset ${keep_frame}" >> "$trajin"
        echo "run" >> "$trajin"
        if [[ ! -f ions.${traj} ]]; then
            echo "strip :WAT outprefix ions" >> "$trajin"
            echo "trajout ions.${traj}" >> "$trajin"
        fi
        printf "autoimage\n" >> "$trajin"
        echo "run" >> "$trajin"
        echo "quit" >> "$trajin"
        echo "Running cpptraj script."
        cpptraj -i "$trajin"  | grep -v 'Could not determine atomic number from'
        echo "Trajectory processed. Write protecting processed files."
        [[ ! -f ${skipname} ]] && return 0
        [[ ! -f ${strip_name} ]] && return 0
        traj_size=$(wc -c "$traj" | awk '{print $1}')
        expected_skip_size=$(( 100 * traj_size / keep_frame / skip_size_buffer))
        expected_strip_size=$(( solute_percent * traj_size / 100 )) # Rounds up. Use bc if precision needed.
        skip_size=$(wc -c "$skipname" | awk '{print $1}')
        strip_size=$(wc -c "$strip_name" | awk '{print $1}')
        if [[ ${skip_size} -lt ${expected_skip_size} ]]; then
          printf "WARNING: Skipped frame trajectory is too small.\t% s \n" "${skipname}"
          printf "WARNING: Actual size: %s\n WARNING: Expected size: %s\n" "${skip_size}" "${expected_skip_size}"
          return 0
        elif [[ ${strip_size} -lt ${expected_strip_size} ]]; then
          printf "WARNING: Solvent stripped trajectory is too small.\t% s \n" "${strip_name}"
          printf "WARNING: Actual size: %s\n WARNING: Expected size: %s\n" "${strip_name}" "${expected_strip_size}"
          return 0
        fi
        [[ "$write_protect" == "True" ]] && chmod -w ${strip_name} ${skipname}
        if [[ ${delete_old_traj} == "True" ]]; then
            chmod +w "${traj}"
            rm "${traj}"
            printf "Removed full length trajectory: %s\n." "$traj"
        fi
        sleep 2
    fi
}

unset serial
unset glob_pattern
while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.

    case $arg in
      -p)
        glob_pattern=$1
        shift
        ;;
      -serial)
        serial="True"
        ;;
      -delete)
        delete_old_traj="True"
        ;;
      -keep)
        keep_frame=$1
        shift
        ;;
      -np)
        write_protect="False"
        ;;
    esac
done

echo "Starting trajectory cleaning run."
if [[ "$glob_pattern" == './' ]]; then
    path_loop './'
else
    path_loop "$glob_pattern"
fi