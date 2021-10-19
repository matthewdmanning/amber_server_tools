#!/usr/bin/env bash
module load amber/16

keep_frame=10
not_running_time=600 # Criterion for deciding whether a trajectory is being written to by running sim (in seconds).

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
    current_time=$(date +%s)
    modified_time=$(date +%s -r ${traj})
    modified_time=$(( current_time - modified_time - not_running_time ))
    echo ${not_running_time}
    printf "Time since %s was last modified: %s.\n" "${traj}" "${modified_time}"
    if [[ ${modified_time} < ${not_running_time} ]]; then
        echo "dormant"
    else
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
    if [[ ${modified_time} > 0 ]]; then
        echo "This traj: ${traj}"
        echo "parm ${system}.prmtop" > traj.in
        echo "trajin ${traj}" >> traj.in
        echo $skipname
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
        echo "Trajectory processed."
        if [[ -f ${skipname} ]] && [[ -f ions.${traj} ]]; then
            chmod +w ${traj}
            rm ${traj}
            echo "Full length trajectory removed."
        fi
        sleep 2
    fi
}

unset serial
unset glob_pattern
glob_pattern="$1"
serial="$2"
echo "Starting trajectory cleaning run."
if [[ $1 == './' ]]; then
    path_loop './'
else
    path_loop "$glob_pattern"
fi