#!/usr/bin/env bash
module load amber/16

keep_frame=10
dormant_cutoff_seconds=600 # Criterion for deciding whether a trajectory is being written to by running sim (in seconds).
delete_old_traj="False"

path_loop(){
search_pattern="$1"
for path in *$search_pattern*/; do
    if [[ -d ${path} ]] && [[ ${path} != "ins/" ]]; then
        cd $path
        system=${path/'/'}
        #echo "${system}"
        traj_loop "$system"
        cd ..
    else
        for parm in *.prmtop; do
            if [[ -f ${parm} ]] && [[ ${parm} != "ions"* ]] && [[ ${parm} != "strip"* ]]; then
                printf "Running in this directory.\n"
                system=${parm/'.prmtop'}
                if [[ -z ${serial} ]]; then
                    traj_loop "$system" &
                else
                    traj_loop "$system"
                fi
            fi
        done
    fi
done
}

traj_loop(){
    system="$1"
    for traj in *.nc; do
        if [[ -f ${traj} ]]; then
            strip_traj "$traj" "$system"
        fi
    done
}

strip_traj(){
    traj=$1
    system=$2
    if [[ ${traj} == "ion"* ]] || [[ ${traj} == "strip"* ]] || [[ ${traj} == *"skip"* ]] || [[ ${traj} == "strip"* ]]; then
        return 0
    fi
    current_time=$(date +%s) #Gives echo time in seconds.
    modified_time=$(date +%s -r ${traj})
    dormant_time=$(( current_time - dormant_time ))
    #printf "Time since %s was last modified %s ago.\n" "${traj}" "${dormant_time}"
    if [[ ${dormant_time} -gt ${dormant_cutoff_seconds} ]]; then
        printf "%s has not been modified for more than %s.\n" "${traj}" "${dormant_cutoff_seconds}"
    else
        printf "%s might still be active. It was last modified %s seconds ago. Going to next traj. \n" "${traj}" "${dormant_time}"
        return 0
    fi
    trimname=${traj%'.nc'}
    skipname="${trimname}.skip10.nc"
    strip_name="ions.${traj}"
    if [[ -f "$skipname" ]]; then
        printf "Skipped frame trajectory already exists. %s\n" "${skipname}"
    fi
    if [[ -f "$strip_name" ]]; then
        printf "Stripped trajectory already exists. %s\n" "$strip_name"
    fi
    if [[ ${dormant_time} -gt 0 ]]; then
        echo "This traj: ${traj}"
        echo "parm ${system}.prmtop" > traj.in
        echo "trajin ${traj}" >> traj.in
        echo ${skipname}
        echo "trajout ${skipname} offset ${keep_frame}" >> traj.in
        echo "run" >> traj.in
        if [[ ! -f ions.${traj} ]]; then
            echo "strip :WAT outprefix ions" >> traj.in
            echo "trajout ions.${traj}" >> traj.in
        fi
        printf "autoimage\n" >> traj.in
        echo "run" >> traj.in
        echo "quit" >> traj.in
        echo "Running cpptraj script."
        cpptraj -i traj.in  | grep -v 'Could not determine atomic number from'
        echo "Trajectory processed. Write protecting processed files."
        chmod -w ${strip_name} ${skipname}
        if [[ -f ${skipname} ]] && [[ -f ions.${traj} ]] && [[ ${delete_old_traj} == "True" ]]; then
            chmod +w ${traj}
            rm ${traj}
            echo "Full length trajectory removed."
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
        shift 1
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
    esac
done

echo "Starting trajectory cleaning run."
if [[ "$glob_pattern" == './' ]]; then
    path_loop './'
else
    path_loop "$glob_pattern"
fi