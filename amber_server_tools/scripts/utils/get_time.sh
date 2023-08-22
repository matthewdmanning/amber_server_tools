#!/usr/bin/env scripts
#RED='\e[31m%s\e[0'
#NC='\033[0m' # No Color

#function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
#function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
#function trim(s) { return rtrim(ltrim(s)); }

get_last_time(){
local sim_time=0
for output in *out; do
    search_string="TIME(PS)"
    if [[ ! -f ${output} ]]; then
        break
    fi
    local new_time="0.000"
    new_time=`awk '$4=="TIME(PS)" {print $6}' ${output} | tail -1`
    if [[ -z ${new_time} ]]; then
        continue
    fi
    new_time="${new_time::-4}"
    if [[ $new_time -gt "$sim_time" ]]; then
        local sim_time="$new_time"
        out_file="$output"
    fi
done
if [[ ${sim_tim} == 0 ]]; then
    return 0
elif [[ ${#sim_time} -gt 3 ]]; then
    #printf "Longest simulation time recorded is %s%s.%s ns%s is in %s.\n" "${RED}" "${sim_time::-3}" "${sim_time: -3}" "${NC}" "out_file"
    printf "Longest simulation time recorded is %s.%s ns in %s.\n" "${sim_time::-3}" "${sim_time: -3}" "$out_file"
else
    #printf "Longest simulation time recorded is %s%s ps%s is in %s.\n" "${RED}" "${sim_time}" "${NC}" "out_file"
    printf "Longest simulation time recorded is %s ps in %s.\n" "${sim_time}" "$out_file"
fi
print_thermo "$out_file"
print_barostat "$out_file"
#get_amber_input "$out_file" "ntwr "
#get_amber_input "$out_file" "ntx "

}

get_amber_input(){

    local out_file="$1"
    local param="$2"
    local input_string="$param*="
    if [[ ! -f ${out_file} ]] || [[ -z ${input_string} ]]; then
        printf "File %s does not exist.\n" "$out_file"
        return 0
    fi
    #grep -m 2 "$input_string" "$out_file"
    #grep "$input_string" "$out_file"
    local out_block=$(grep "General flags:" "$out_file" -A 40)
    #printf "$out_block"
    #echo "Echo output: $out_line"
    #echo ${out_line[@]}
    #printf "%s: " "$input_string"
    local setting=$(sed -n -e "s/$input_string //p " <<< "$out_block" | awk '{print $1}')
    setting=${setting/','}
    #printf "%s: %send\n" "$input_string" "$setting"
    printf "$setting"
    return 1
    #awk '{for (i=1;i<=NF;i++)if($i=="$input_string") {print $(i+2)}}' "$out_file"
    #awk -F1 "/$input_string/ {print $3}" "$out_file"
    #grep "$input_string" "$out_file"
    #echo '/${input_string}/ {print $3}' "$out_file"
    #input=$(awk '/$input_string/ {for (i=1;i<=NF;i++) if ($i == "$input_string") print $(i+2) }' "$out_file")
    #printf "%s: %s\n" "$input_string" "$input"
}

folder_loop(){
    for folder in */; do
        if [[ ! -d ${folder} ]]; then
            printf "Folder not found.\n"
        fi
        cd "$folder"
        printf "%s  " "${folder/'/'}"
        get_last_time
        cd ..
    done
}


print_barostat(){
    #local setting="$1"
    local amber_output="$1"
    local setting=$(get_amber_input "$amber_output" "ntp ")
    echo "$setting"
    if [[ $setting == *1* ]]; then
        printf "Barostat: Berendsen: "
        printf "taup="; get_amber_input "$amber_output" "taup " ; printf "ps,\t"
    elif [[ $setting == *2* ]]; then
        printf "Barostat: Monte Carlo: "
        printf "mcbarint="; get_amber_input "$amber_output" "mcbarint "
    else
        printf "No barostat method detected...That's weird...\n"
        printf "Barostat: %s\n\n" "$setting"
        return 0
    fi
    printf "pres0="; get_amber_input "$amber_output" "pres0 "  ; printf "\n"
    return 1
}

print_thermo(){
    #local setting="$1"
    local amber_output="$1"
    grep -q Langevin "$amber_output"

    #local setting=$(get_amber_input "$amber_output" "ntt ")
    printf 'Temperature: '
    get_amber_input "$amber_output" "temp0 "
    printf "K\n"
    if grep -q "Berendsen" "$amber_output"; then
        printf "Berendsen: tautp="
        get_amber_input "$amber_output" "tautp "
    elif grep -q "Andersen" "$amber_output"; then
        printf "Andersen: vrand="
        get_amber_input "$amber_output" "vrand "
    elif grep -q Langevin "$amber_output"; then
        printf "Langevin gamma_ln="
        get_amber_input "$amber_output" "gamma_ln "
    elif grep -q "Isokinetic" "$amber_output"; then
        printf "Optimized Isokinetic Nose-Hoover chain ensemble: "
        printf "gamma_ln="; get_amber_input "$amber_output" "gamma_ln "
        printf ", nkija="; get_amber_input "$amber_output" "nkjia "
        printf ", idistr="; get_amber_input "$amber_output" "idistr "
    elif grep -q "Stochastic" "$amber_output"; then
        printf "Stochastic Nose-Hoover RESPA integrator: "
        printf "nkija="; get_amber_input "$amber_output" "nkjia "
        printf ", sinrtau="; get_amber_input "$amber_output" "sinrtau "
    else
        printf "No thermostat method detected in output file...That's weird...\n"
        #printf "Thermostat: %s\n\n" "$setting"
        return 0
    fi
    printf "\n"
    return 1
}


if [[ "$1" == "-f" ]]; then
    folder_loop
else
    get_last_time
fi