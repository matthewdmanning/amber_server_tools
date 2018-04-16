#!/usr/bin/env bash

# Creates and runs Tcl for loading multiple trajectories into VMD with optional offset.
startup_vmd='/home/mdmannin/.vmdrc'

strip_parm(){
    local in_parm="$1"
    local in_rst="$2"
    printf "parm %s\n" "$in_parm" > traj.in
    printf "trajin %s\n" "$in_rst" >> traj.in
    printf "strip :WAT outprefix ions\n" >> traj.in
    printf "run\n" >> traj.in
    printf "quit\n" >> traj.in
    cpptraj -i traj.in

}

load_traj(){
    local path_prefix="$1"
    #printf "%s %s\n" "${start_traj}" "$end_traj"
    for traj_num in `seq ${start_traj} ${end_traj}`; do
        #printf "%s\n" "$traj_num"
        traj_name="${path_prefix}.${run_type}${traj_num}${traj_format}"
        #printf "%s" "$traj_name"
        if [[ ! -f ${traj_name} ]]; then
            continue
        fi
        printf "mol addfile %s %s %s step %s waitfor all\n" "$traj_name" "$start_frame" "$end_frame" "$offset" >> "$tcl_script"
    done
}


load_mol(){
    local path="$1"
    local system="$2"
    for mol in "$path""$prefix""$system""$top_format"; do
        if [[ ! -f ${mol} ]]; then
            local full_parm="$system""$top_format"
            local rst_in="$system""$restart_format"
            #printf "Molecule %s not found.\n" "$mol"
            cd "$path"
            strip_parm "$full_parm" "$rst_in"
            cd ..
        fi
        printf "mol new %s waitfor all\n" "$mol" >> "$tcl_script"
        mol_pattern=${mol/"$top_format"}
        load_traj "$mol_pattern"; wait
    done
}

run_vmd(){
    printf
    vmd -e "$tcl_script"
}

# Default settings.
top_format=".prmtop"
restart_format=".rst7"
traj_format=".nc"
run_type="md"
prefix='ions.'
tcl_script="vmd_loader.tcl"
start_frame='first'
end_frame=0
start_traj=1
end_traj=100
# Reading user inputs.
offset="$1"
if [[ "$offset" -gt 0 ]]; then
    shift
else
    printf "Invalid value, %s, set for frame offset. Using 1 instead.\n" "$1"
fi
while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.

    case $arg in
        -p)
            glob_pattern="$1"; shift
            ;;
        -pre)
            prefix="$1"; shift
            ;;
        -pf)
            top_format="$1"; shift
            ;;
        -tf)
            traj_format="$1"; shift
            ;;
        -traj)
            if [[ $1 == "-"* ]] || [[ $2 == "-"* ]]; then
                printf "Not enough arguments passed to -traj keyword. Must include both starting and ending trajectory numbers. Loading all trajectories.\n"
                continue
            fi
            start_traj="$1"
            end_traj="$2"; shift 2
            if [[ ! "$start_traj" -ge 1 ]]; then
                printf "Value of %s passed to \$start_traj. Setting to 1.\n" "$start_traj"
            fi
            if [[ "$end_traj" -gt 1 ]]; then
                continue
            else
                printf "Value of %s passed to \$end_traj. Setting to 100.\n" "$end_traj"
            fi
            ;;
        -run)
            run_type="$1"; shift
            ;;
        -f)
            if [[ $1 == "-"* ]] || [[ $2 == "-"* ]]; then
                printf "Not enough arguments passed to -f keyword. Must include both starting and ending frame numbers (0 index).\n"
            fi
            start_frame="$1"
            end_frame="$2"; shift 2
            if [ ! "$start_frame" -ge 2 ]; then
                printf "Value of %s passed to \$start_frame. Setting to 'first'.\n" "$start_frame"
                start_frame='first'
            fi
            if [[ "$end_frame" -gt 1 ]]; then
                continue
            else
                printf "Value of %s passed to \$end_frame. Setting to '0', reading until last frame.\n" "$end_frame"
                end_frame=0
            fi
            ;;
        esac
done
# Clear script.
#printf "source %s\n" "$startup_vmd" "# Automated loading script." > "$tcl_script"
printf "# Automated loading script.\n" > "$tcl_script"
for path in *"$glob_pattern"*/; do
    if [[ ! -d ${path} ]]; then
        printf "Directory %s not found.\n" "$path"
    fi
    system=${path/'/'}
    load_mol "$path" "$system"; wait
done
run_vmd
