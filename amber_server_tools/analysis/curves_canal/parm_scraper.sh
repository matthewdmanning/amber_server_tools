#!/usr/bin/env scripts

# Model function for searching for text between the two specified strings in the specified file.

generic_get_between_two_string(){

local file_name=$1
local start_string=$2
local end_string=$3

string_between=`awk '/${start_string}/,/${end_string}/' ${file_name}`
printf "%s\n" "${string_between}"

read -ra RESIDUES -d '' <<< "$string_between"
echo $RESIDUES[*]



}


get_nucleic_indices(){

parm_name=$1
printf "$parm_name"
start_string='RESIDUE_LABEL'
end_string='RESIDUE_POINTER'
#printf "awk '/%s/,/%s/' %s \n" "${start_string}" "${end_string}" "${parm_name}"
#awk_string=`printf "awk '/%s/,/%s/' %s \n" "${start_string}" "${end_string}" "${parm_name}"`
#echo ${awk_string}
#awk $awk_string
#string_between=`awk '/${start_string}/,/${end_string}/' ${file_name}`
#read string_between <<< $( echo ${file_name} | awk '/RESIDUE_LABEL/,/RESIDUE_POINTER/' ${1} )
#shift ${string_between}; shift ${string_between}

line_num_start=`grep

printf "%s\n" "${string_between}"
# read -ra RESIDUES -d '' <<< "$string_between"
echo $RESIDUES[*]


na_start_res=0
residue_counter=1
reading_frame_on="false"
current_sequence=''
for residue in ${RESIDUES[@]}; do
    if [[ ${residue} == [ACGTU]5 ]]; then
        if [[ ${reading_frame_on} == "false" ]]; then
            reading_frame_on="true"

        else
            printf "Sequential 5' bases detected. Topology file %s is likely corrupted.\n Trying to continue.\n." "$parm_name"
        fi
        if [[ ${na_start_res} -eq 0 ]]; then
            na_start_res=${residue_counter}
            printf "Start of new nucleic acid strand detected at residue %s.\n" "${residue_counter}"
        fi
    elif [[ ${residue} == [ACGTU] ]]; then
        current_sequence+=${residue}

    fi

done

for parm in *.prmtop; do
    get_nucleic_indices "$parm"
done
}