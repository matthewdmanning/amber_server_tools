#!/usr/bin/env scripts


function get_traj_nums(){

    local sys_path=$1
    local system=$2
    # Prefix and suffix only needed to filter for "ions.", "strip.", "skip10.", etc.
    # Passing empty strings will get all .nc trajectories.
    # Might need to add to function to include traj numbers from same naming prefix/suffix.
    local prefix=${3}
    local suffix=${4}
    local __array_name=$5

    traj_array=()
    for traj in ${prefix}*${suffix}*nc; do
        if [[ $traj != *skip* ]]; then
            if [[ ${prefix} ]]; then
                local no_prefix=${traj'$prefix.$system.md'}
            else
                local no_prefix=${traj}
            fi
            echo $no_prefix
            if [[ ${suffix} ]]; then
                local raw_num=${no_prefix'$suffix.nc'}
            else
                local raw_num=${noprefix}
            fi
            local traj_num=${raw_num/'.'}
        fi
        traj_array+=($traj_num)
    done
    IFS=$'\n' sorted=($(sort <<<"${traj_array[*]}"))
    unset IFS

    if [[ "$__array_name" ]]; then
        eval $__array_name="'$traj_array'"
    else
        echo "$traj_array"
    fi

}

function get_continuous(){
    local num_array=$1
    local __return_array=$2
    local cont_array=()
    ind=0
    array_list=echo `seq $num_array[0] $num_array[-1]`
    for number in $@array_list; do
        if [ ${number} == ${num_array[ind]} ]; then
            $cont_array=+$(number)
            ind=+1
            continue
        else
            break
        fi
    done

    if [[ "$__return_array" ]]; then
        eval $__return_array="'cont_array'"
    else
        echo "$cont_array"
    fi
}

function get_continuous_traj(){
    local sys_path=$1
    local system=$2
    local prefix=$3
    local suffix=$4
    local __return_array=$5
    get_traj_nums "$sys_path" "$system" "$prefix" "$suffix" traj_num_array
    get_continuous "$traj_num_array" cont_array
    if [[ "$__return_array" ]]; then
        eval $__return_array="'cont_array'"
    else
        echo "$cont_array"
    fi
}

# Checks if all trajectories in a folder have been stripped of water (and ions).
function check_stripped(){
    local sys_path=$1
    local system=$2
    local prefix=$3
    local full_traj_nums=$(get_traj_nums "$sys_path" "$system")
    if [[ $prefix ]]; then
        local stripped_traj_nums=$(get_traj_nums "$sys_path" "$system" "$prefix")
    else
        local strip_traj_nums=$(get_traj_nums "$sys_path" "$system" "strip")
        local ions_traj_nums=$(get_traj_nums "$sys_path" "$system" "ions")
        local non_stripped_traj=()
        local non_ioned_traj=()
    fi
}

function elements_not_in_both() {
    search_for_array=$1
    search_in_array=$2
    common_array=()
    unique_array=()
            for for_element in ${search_for_array}; do
                for in_element in "${search_in_array[@]}"; do
                    if [[ ${in_element} == ${for_element} ]]; then
                        common_array+=($for_element)
                        continue 2
                    fi
                    uncommon_array+=($for_element)
                done
            done
}