#!/usr/bin/env bash


# Loop through relevant files. Which?
# *.nc, *.prmtop, *.rst7, *.out,
# Check if files already exist in destination.
# Check if file size is approx same.
# Check if file contents (partial) are same.
# Move/copy files. [ Overwrite incomplete files? ]
# Separate already saved files.

keep_frame=10
dormant_cutoff_seconds=600 # Criterion for deciding whether a trajectory is being written to by running sim (in seconds).
write_protect="True"
deep_check="False"
create_folder="False"
copied_folder="False"
max_md_num=200
solute_percent=2 # Minimum file size of stripped trajectory as percentage of original trajectory
skip_size_buffer=98 # Allows (100-x) undershoot of file size of solvent strip trajectory.
logfile="mover.log"

path_loop(){
search_pattern=$1
for path in *"$search_pattern"*/; do
    if [[ -d ${path} ]] && [[ ${path} != "ins/" ]]; then
        cd "${path}" || continue
        system=${path/'/'}
        #echo "${system}"
        if [[ -z ${serial} ]]; then
            move_file "$system"
        fi
        cd ..
    fi
done
}


#file_size=$(stat -c "%s" FILE)
#file_size=$(wc -c < FILE)
bigger_file(){

  first=$1
  second=$2
  [[ -f "${first}" && -f "${second}" ]] || return 3
  first_size=$(stat -c "%s" "$first")
  second_size=$(stat -c "%s" "$second")
  if [[ ${first_size} -gt ${second_size} ]]; then
    return 0
  elif [[ ${second_size} -lt ${first_size} ]]; then
    return 1
  else
    return 2
  fi

}

move_file(){
    system="$1"
    destination_sub="${destination/'/'}/${system}"
    if [[ ! -d ${destination_sub} ]] && [[ "${create_folder}" == "True" ]]; then
      mkdir "${destination_sub}"
    elif [[ ! -d ${destination_sub} ]] && [[ "${create_folder}" == "False" ]]; then
      printf "Subdirectory %s does not exist. Not moving files in source directory %s.\n" "$destination_sub" "$system"
    fi
    #while [[ $(ls -A | head -c1 | wc -c) -eq 0 ]]; do
    # Loop through files.
    for system_file in *"${system}"*.{nc,rst7,out,mdout,prmtop}; do
        # Check that file exists and hasn't been recently modified.
        [[ ! -f ${system_file} ]] && continue
        if [[ ${only_stripped} == "True" ]] && [[ "$system_file" == "${system}.md[1-${max_md_num}].nc" ]]; then
          printf "Not moving full-length trajectory %s. Use traj_cleaner.sh first.\n" "${system_file}" >> "$logfile"
          continue
        fi
        current_time=$(date +%s) #Gives echo time in seconds.
        system_time=$(date +%s -r ${system_file})
        dormant_time=$(( current_time - system_time ))
        #printf "Time since %s was last modified %s ago.\n" "${system_file}" "${dormant_time}"
        if [[ ${dormant_time} -le ${dormant_cutoff_seconds} ]]; then
            printf "%s might still be active. It was last modified %s seconds ago. Going to next file. \n" "${system_file}" "${dormant_time}" >> "$logfile"
            continue
        fi
        # File doesn't exist in Destination folder.
        destination_file="${destination_sub}/${system_file}"
        if [[ ! -s "${destination_file}" ]]; then
          chmod +w "${system_file}"
          builtin mv ${system_file} ${destination_sub} && printf "File %s doesn't exist in destination. Moving now.\n" "$system_file" && continue
        fi
        if [[ ${check_time} == "True" ]]; then
          destination_time=$(date +%s -r ${destination_file})
          if [[ ${destination_time} -ge ${system_time} ]]; then
            printf "Destination file is more recent or the same as the source.\n" >> "$logfile"
          fi
        fi
        #Check file sizes and/or content
        big_file=$(bigger_file system_file destination_file)
        if [[ "$deep_check" != "True" ]] && [[  big_file -eq 0 ]]; then
          chmod +w ${system_file}
          builtin mv ${system_file} ${destination_file} && printf "Source file %s is bigger than current file.\n" "$system_file" && continue
        elif [[ "$deep_check" == "True" ]] && [[ $(cmp --silent "$system_file" "$destination_file") ]]; then
          chmod +w ${system_file}
          builtin mv ${system_file} ${destination_file} && printf "Source file %s is not identical to destination file.\n" "$system_file" && continue
        fi

        printf "A copy of %s already exists in the destination.\n" "$system_file"
        if [[ "$copied_folder" == "True" ]]; then
          [[ ! -d "already_copied" ]] && mkdir "already_copied"
          mv ${system_file} already_copied/ && printf "File %s moved to already_copied folder.\n" "$system_file" >> "$logfile"
        elif [[ "$delete_old_traj" == "True" ]]; then
          rm "$system_file" && printf "%s has been deleted.\n" "$system_file" >> "$logfile"
        fi
    done
}


unset serial
unset glob_pattern
unset destination

while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.

    case $arg in
      -p)
        glob_pattern=$1
        shift
        ;;
      -d)
        destination=$1
        shift
        ;;
      -cf) # Create folder for already copied files in source subdirectory.
        copied_folder="True"
        ;;
      -delete)
        delete_old_traj="True"
        ;;
      -time)
        check_time="True"
        ;;
      -np)
        write_protect="False"
        ;;
      -deep)
        deep_check="True"
        ;;
      -c)
        create_folder="True"
        ;;
      -l)
        logfile=$1
        shift
        ;;
      -unstripped)
        only_stripped="False"
        ;;
    esac
done

if [[ "$copied_folder" == "True" ]]; then
  delete_old_traj="False"
fi

[[ -z "${destination}" ]] && printf "No destination given. Script not run.\n" && return 0

printf "Moving files.\n"
if [[ "$glob_pattern" == './' ]]; then
    path_loop './'
else
    path_loop "$glob_pattern"
fi