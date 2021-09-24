#!/usr/bin/env bash
# Script for running MD simulations using AMBER

module load amber


### Displays name of job on server and Cacti.
if [[ -f /home/common/user_jobs/PID_log.sh ]]; then
    jobname='source /home/common/user_jobs/PID_log.sh'
else
#jobname=`echo "No PID_log.sh file found."`
    jobname="wait;"
fi

### Set GPU cards to use for this job(s)
#export CUDA_VISIBLE_DEVICES=0,1      # this is GPU card number

check_md_inputs(){
    local run_type=$1
    if [[ -d ins/ ]]; then
        ins_dir="ins"
    elif [[ -d ../ins ]]; then
        ins_dir="../ins"
    fi

    ### Check MDIN files for correct parameters
    if ls ins/*weak* 1> /dev/null 2>&1; then
        weak="True"
        thermo=weak
    fi
    if ls ins/*lang* 1> /dev/null 2>&1; then
        lang="True"
        thermo=lang
    fi
    if [[ "$weak" == "True" ]] && [[ $lang == "True" ]]; then
        printf "Both Berendsen and Langevin thermostat input files detected. Choose 'weak' or 'lang'..."
        read thermo
    elif [[ -z $thermo ]]; then
        printf "Thermostatting method not detected from mdin names.\n"
        #read thermo
        quit
    fi

    # Define AMBER input files.
    minin="${ins_dir}/min.pme.mdin"
    heatin="${ins_dir}/heat.${thermo}.pme.mdin"
    eq1in="${ins_dir}/equil1.${thermo}.pme.mdin"
    eq2in="${ins_dir}/equil2.${thermo}.pme.mdin"
    mdin="${ins_dir}/md.${thermo}.pme.mdin"

    if [[ "$run_type" == 'md' ]] && [[ -f ${mdin} ]]; then
        return 1
    fi
    # Check AMBER input files.
    for infile in ${minin} ${heatin} ${eq1in} ${eq2in} ${mdin}; do
        if [[ ! -f ${infile} ]]; then
            printf "%s is missing. Terminating run.\n" "$infile"
            exit 0
        fi
    done
}

strip_cpptraj_script(){
	local system="$1"
	local path="$2"
	local md_num="$3"
	local keep_frame_step="$4"
	local strip_ions="$5"

    local trajin="${path}/traj.in"
    chmod +w "$trajin"
    local parm="${path}/${system}.prmtop"
	local in_traj="${path}/${system}.md${md_num}.nc"
    local skip_traj="${path}/${system}.md${md_num}.skip${keep_frame_step}.nc"
    local stripped_traj="${path}/${prefix}.${system}.md${md_num}.nc"
    #Load topology and trajectory files.
	printf "parm %s.prmtop\n" "${parm}" > "$trajin"
	printf "trajin %s\n" "${in_traj}" >> "$trajin"
	# Center coords around first molecule. Output every 10th frame with all atoms, including solvent."
    printf "autoimage\n" >> "$trajin"

	printf "trajout %s offset %s\n" "${skip_traj}" "{$keep_frame_step}" >> "$trajin"
	printf "run\n" >> "$trajin"
	# Strip trajectory of water [and ions] and output every frame.
	if [[ ${strip_ions} == 1 ]]; then
	    local prefix=strip
		printf "strip :WAT,Na+,Cl- outprefix strip\n" >> "$trajin"
    else
        local prefix=ions
		printf "strip :WAT outprefix ions\n" >> "$trajin"
	fi
    printf "trajout %s\n" "$stripped_traj">> "$trajin"
	printf "run\n" >> "$trajin"
	printf "quit\n" >> "$trajin"
	cpptraj -i "$trajin"
	if [[ -f ${stripped_traj} ]] && [[ -f ${skip_traj} ]]; then
	    rm ${in_traj}
    else
        printf "Trajectory stripping failed. Original trajectory not deleted.\n"
    fi
}

cpu_minimize(){

	local path=$1
	local system=$2
	local md_loops=$3
	local parm="${path}/${system}.prmtop"
	local leaprst="${path}/${system}.rst7"
	local minrst="${path}/${system}.min.rst7"
	local minout="${path}/${system}.min.out"
	local info="${path}/mdinfo"

    if [[ ! -f ${minrst} ]]; then
        printf "Minimization: %s\n"  "${system}"
        printf "Number of cores per process: %s\n" "$cpu_num"
        $cpu -i ${minin} -o ${minout} -p ${parm} -c ${leaprst} -ref ${leaprst} -r ${minrst} -inf ${info} &
        $jobname min_$system; wait
        if [[ -f ${minrst} ]]; then
            printf "Write-protecting .mdout and .rst7 files from %s.\n" "$system"
            chmod -w ${minout} ${minrst}
            if [[ $md_loops -gt 0 ]]; then
                amber_run "$path" "$system" "$md_loops"
            fi
        else
            printf "Minimization of %s failed. Terminating simulation run.\n\n" "$system"
            return 0
        fi
    elif [[ -f ${minrst} ]]; then
        amber_run "$path" "$system" "$md_loops"
    fi
}

run() {
    system=$1
    method=$2
    while [[ $1 = -* ]]; do
        arg=$1; shift           # shift the found arg away.
        case $arg in
            -i)
                mdin=$1
                ;;
            -o)
                mdout=$1
                ;;
            -p)
                parm=$1
                ;;
            -c)
                in_coords=$1 #.rst7 of starting config
                ;;
            -ref)
                ref=$1
                ;;
            -r)
                rst=$1 # .rst7 output of this run
                ;;
            -x)
                traj=$1
                ;;
            -inf)
                info=$1
                ;;
            -n)
                run_name=$1 # ex. heat, equil2, md4, etc.
                ;;
            esac
    done
	if [[ ( ! -f ${rst} || ${overwrite} == "True" ) && -f ${in_coords} ]]; then
	    if [[ ${overwrite} == "True" ]]; then
	        printf "Files %s will be overwritten.\n" "${in_coords} ${traj} ${mdout}"
        fi
        printf "Equilibration 1: %s\n"  "${system}"
        source /usr/local/apps/env/nvidia-smi_sort.sh "$gpu_list"
        $method -i ${mdin} -o ${mdout} -p ${parm} -c ${in_coords} -ref ${ref} -r ${rst} -inf ${info} &
        $jobname "${run_name}_${system}"; wait
        if [[ -f ${rst} ]]; then
            printf "Write-protecting .mdout and .rst7 files from %s.\n" "$system"
            chmod -w ${mdout} ${rst}
            if [[ -f ${traj} ]]; then
                printf "Write-protecting trajectory %s.\n" "$x"
                chmod -w ${traj}
            fi
        else
            printf "Equilibration 1 for %s failed. Terminating run.\n" "$system"
            exit
        fi
        sleep 3
    elif [[ ! -f ${in_coords} ]]; then
        printf "Previous restart file %s does not exist. Trying next step." "${in_coords}"
    fi
}

method_loop(){
    printf "Starting method loop.\n"
    local path=$1
	  local system=$2
    local in_dir=$3
    local ref=$4
    local prev_method=$5

    local info="${path}/mdinfo"
    local parm="${path}/${system}.prmtop"

    for method_num in `seq ${#method_array[@]}`; do
        local method=${method_array[method_num]}
        printf "Next run type is %s.\n" "$method"
        if [[ "$method_num" -eq 0 ]]; then
            if [[ ! -z "$prev_method" ]]; then
                local in_rst="${path}/${system}.${prev_method}.rst7"
            elif [[ -z "$prev_method" ]]; then
                local in_rst="${path}/${system}.rst7"
            fi
        elif [[ $method_num -gt 0 ]]; then
            prev_index=$(( method_num - 1 ))
            prev_method=${method_array[prev_index]}
            local in_rst="${path}/${system}.${prev_method}.rst"
        else
            printf "Something went wrong method_loop...Check bash script\n"
            return 0
        fi
        # Define file names.
        if [[ -z "$ref" ]]; then
            local ref="$in_rst"
        fi
        local mdout="${path}/${system}.${method}.out"
        local out_rst="${path}/${system}.${method}.rst7"
        if [[ "$method" == *prod* ]] || [[ "$method" == *md* ]]; then
            local mdnc="${path}/${system}.${method}.nc"
        fi
        # Get input file for this run.
        for input in ${ins_dir}/*; do
            if [[ "$input" == *"$method"* ]]; then
                local mdin="$input"
            fi
        done
        if [[ -z $mdin ]]; then
            printf "MD input file not found. Ending this run.\n"
            return 0
        fi
        # Run next method.
        #generic_job "$method" "$path" "$mdin" "$mdout" "$parm" "$in_rst" "$ref" "$out_rst" "$method" "$mdnc"
        echo "$method" "$path" "$mdin" "$mdout" "$parm" "$in_rst" "$ref" "$out_rst" "$method" "$mdnc"
    done
}

generic_job(){
	local method=$1; shift
	local path=$1; shift
	local mdin=$1; shift
	local mdout=$1; shift
	local parm=$1; shift
	local in_rst=$1; shift
	local ref=$1; shift
	local out_rst=$1; shift
	local jobname=$1; shift
	local mdnc=$1; shift

	if [[ ! -f ${mdin} ]]; then
	    printf "Input file is missing. Skipping to next run. %s \n" "${mdin}"
	    return 0
    elif [[ ! -f ${in_rst} ]]; then
        printf "Restart coordinates missing. skipping to next run. %s \n" "${in_rst}"
        return 0
    elif [[ ${mdnc} ]] || [[ -f ${mdnc/'/'/'/ions.'} ]] || [[ -f ${mdnc/'.nc'/'.skip10.nc'} ]]; then
        printf "Trajectory already exists. Skipping to next skip. %s \n" "$mdnc"
        return 0
    elif [[ -z "$mdnc" ]]; then
        $gpu -i ${mdin} -o ${mdout} -p ${parm} -c ${in_rst} -ref ${ref} -r ${out_rst} -inf ${info} &

    else
        $gpu -i ${mdin} -o ${mdout} -p ${parm} -c ${in_rst} -ref ${ref} -r ${out_rst} -x ${mdnc} -inf ${info} &
    fi
    $jobname $jobname_$system; wait
    # Check that output exists and is not empty.
    if [[ -f "$out_rst" ]] && [[ $(wc -c "$out_rst") -gt 0 ]]; then
            printf "Write-protecting .mdout, .rst7 files from %s.\n" "$system"
            chmod -w ${mdout} ${out_rst}
        if [[ ! -z "$mdnc" ]] && [[ -f ${mdnc} ]] && [[ $(wc -c "$mdnc") -gt 0 ]]; then
            printf "Keeping every %s frames with solvent.\n" "$keep_frame_step"
            printf "Stripping trajectory.\n"
            strip_cpptraj_script "$system" "$path" 1 "$keep_frame_step" 0 &
            sleep 3
            printf "MD run from %s complete\n" "$mdnc";
        fi
        return 1
    else
        printf "Run failed. No valid restart file found\n."
        return 0
    fi
}

### Function for full simulation sequence: minimization, heat, equils, MD run
amber_run(){
	### Get GPU with most resources
	#export CUDA_VISIBLE_DEVICES=0,1      # this is GPU card number
	### Start running MD.
	local path=$1
	local system=$2
	local md_runs=$3

	### mdout names
	local minout="${path}/${system}.min.out"
	local heatout="${path}/${system}.heat.out"
	local eq1out="${path}/${system}.equil1.out"
	local eq2out="${path}/${system}.equil2.out"
	local md1out="${path}/${system}.md1.out"
	
	### Trajectory names
	local md1nc="${path}/${system}.md1.nc"
	
	### Restart names
	local leaprst="${path}/${system}.rst7"
	local minrst="${path}/${system}.min.rst7"
	local heatrst="${path}/${system}.heat.rst7"
	local eq1rst="${path}/${system}.equil1.rst7"
	local eq2rst="${path}/${system}.equil2.rst7"
	local md1rst="${path}/${system}.md1.rst7"
	
	### prmtop name
	local parm="${path}/${system}.prmtop"
	
	### mdinfo name
	local info="${path}/mdinfo"
	
    # Begin run.
	if [[ ! -f ${heatrst} ]] && [[ -f ${minrst} ]]; then
        printf "Heating: %s\n"  "${system}"
        source /usr/local/apps/env/nvidia-smi_sort.sh "$gpu_list"
        $gpu -i ${heatin} -o ${heatout} -p ${parm} -c ${minrst} -ref ${minrst} -r ${heatrst} -inf ${info} &
        $jobname heat_$system; wait
        if [[ -f ${heatrst} ]]; then
            printf "Write-protecting .mdout and .rst7 files from %s.\n" "$system"
            chmod -w ${heatout} ${heatrst}
        else
            printf "Heating for %s failed. Terminating run.\n" "$system"
            return 0
        fi
        sleep 3
    elif [[ ! -f ${heatrst} ]] && [[ ! -f ${minrst} ]]; then
        printf "No restart found from minimization. Ending this run.\n"
        return 0
    fi

	if [[ ! -f ${eq1rst} ]] && [[ -f ${heatrst} ]]; then
        printf "Equilibration 1: %s\n"  "${system}"
        source /usr/local/apps/env/nvidia-smi_sort.sh "$gpu_list"
        $gpu -i ${eq1in} -o ${eq1out} -p ${parm} -c ${heatrst} -ref ${heatrst} -r ${eq1rst} -inf ${info} &
        $jobname equil1_$system; wait
        if [[ -f ${eq1rst} ]]; then
            printf "Write-protecting .mdout and .rst7 files from %s.\n" "$system"
            chmod -w ${eq1out} ${eq1rst}
        else
            printf "Equilibration 1 for %s failed. Terminating run.\n" "$system"
            return 0
        fi
        sleep 3
    elif [[ ! -f ${heatrst} ]]; then
        printf "Previous restart file %s does not exist. Trying next step." "${heatrst}"
    fi

	if [[ ! -f ${eq2rst} ]]; then
        printf "Equilibration 2: %s\n"  "${system}"
        source /usr/local/apps/env/nvidia-smi_sort.sh "$gpu_list"
        $gpu -i ${eq2in} -o ${eq2out} -p ${parm} -c ${eq1rst} -ref ${heatrst} -r ${eq2rst} -inf ${info} &
        $jobname equil2_$system; wait
        if [[ -f ${eq2rst} ]]; then
            printf "Write-protecting .mdout and .rst7 files from %s.\n" "$system"
            chmod -w ${eq2out} ${eq2rst}
        else
            printf "Equilibration 2 for %s failed. Terminating run.\n" "$system"
            return 0
        fi
        sleep 3
    fi

	if [[ ! -f ${md1rst} ]] && [[ ! -f ${md1nc} ]]  && [[ ! -f ions.${md1nc} ]]  && [[ ! -f ${md1nc/'.nc'/'.skip10.nc'} ]]; then
        printf "Starting MD run #1 from : %s.\n" "${system}"
        source /usr/local/apps/env/nvidia-smi_sort.sh "$gpu_list"
        $gpu -i ${mdin} -c ${eq2rst} -p ${parm} -ref ${eq2rst} -o ${md1out} -r ${md1rst} -x ${md1nc} -inf ${info} &
        $jobname md1_$system; wait
        if [[ -f ${md1rst} ]] && [[ -f ${md1nc} ]]; then
            printf "Keeping every %s frames with solvent.\n" "$keep_frame_step"
            printf "Stripping trajectory.\n"
            strip_cpptraj_script "$system" "$path" 1 "$keep_frame_step" 0 &
            printf "Write-protecting .mdout, .rst7 files from %s.\n" "$system"
            chmod -w ${md1out} ${md1rst}
            sleep 3
            printf "MD run #1 from %s complete\n" "$system";
            md "$path" "$system" "$md_runs"
        else
            printf "MD run #1 from %s failed. Terminating run.\n" "$system"
            return 0
        fi
    elif [[ -f ${md1rst} ]]; then
        if [[ -f ${md1nc} ]] || [[ -f ions.${md1nc} ]]; then
            md "$path" "$system" "$md_runs"
        fi
    fi
}

### Function for single run of MD, continued from previous MD or heat.
### Arguments: path, system_name, number of input .rst7 file (for MD continuation) and number of times to run loop.
md(){
	local path=$1
	local system=$2
	local loops=$3
	local start=$4
	local info="${path}/mdinfo"

#    last_mod_time=0
#    for traj_file in *.nc; do
#        if [[ ! -z ${traj_file} ]]; then
#            for restart in *.rst7; do
#                if [[ ! -z ${restart} ]]; then
#                    continue
#                fi
#                new_mod_time=$(($(date +%s) - $(date +%s -r ${restart})))
#                if [[ $last_mod_time == 0 ]] || [[ $last_mod_time > $new_mod_time ]]; then
#                    last_mod_time=$new_mod_time
#                    last_restart=${restart}
#                fi
#            done
#
#        fi
#    done
    # Identify the first valid restart file, where the next trajectory does not exist.
    if [[ -z "$start" ]]; then
        local start=1
        local next=2
        while [[ ! -f ${path}/${system}.md${start}.rst7 ]] || [[ -f ${path}/${system}.md${next}.nc ]] || [[ -f ${path}/ions.${system}.md${next}.nc ]] || [[ -f ${path}/${system}.md${next}.skip10.nc ]]; do
            if $debug_progress_check; then
                if [[ ! -f ${path}/${system}.md${start}.rst7 ]]; then
                    printf "Restart file does not exist. \t\t%s\n" "$start"
                elif [[ -f ${path}/${system}.md${next}.nc ]]; then
                    printf "Original trajectory exists. \t\t%s\n" "$next"
                elif [[ -f ${path}/ions.${system}.md${next}.nc ]]; then
                    printf "Stripped trajectory exists. \t\t%s\n" "$next"
                elif [[ -f ${path}/${system}.md${next}.skip10.nc ]]; then
                    printf "Skip trajectory exists. \t\t%s\n" "$next"
                else
                    printf "We could stop here. %s\n" "$start"
                fi
            fi
            start=$(( start + 1))
            next=$(( start + 1 ))
            printf "%s %s" "$start" "$next"
            if [[ ${start} -gt 100 ]]; then
                printf "No valid restart file found for %s. Terminating run.\n\n" "$system"
                return 0
            fi
        done
    else
        local next=$(( start + 1 ))
        echo "$next"
    fi
    printf "First restart found is %s. Starting run #%s.\n" "$start" "$next"

	for i in `seq 1 $loops`; do
	    local prev=$(( start + i - 1 ))
		local current=$(( prev + 1 ))

		### File names
		local parm="${path}/${system}.prmtop"
		local prevrst="${path}/${system}.md${prev}.rst7"
		local mdrst="${path}/${system}.md${current}.rst7"
		local mdnc="${path}/${system}.md${current}.nc"
		local mdout="${path}/${system}.md${current}.out"
		local ref="${path}/${system}.equil2.rst7"

        if [[ ! -f ${ref} ]]; then
            local ref="${path}/${system}.heat.rst7"
        fi
        # Double check to avoid overwriting existing traj.
        if [[ -f ${mdnc} ]] || [[ -f ${path}/ions.${system}.md${current}.nc ]] || [[ -f ${mdnc/'.nc'/'.skip10.nc'} ]]; then
            printf "Existing trajectory found. Moving to next. Traj:%s\n" "$mdnc"
            continue
        fi
		if [[ -f ${prevrst} ]]; then
        	source /usr/local/apps/env/nvidia-smi_sort.sh $gpu_list
            printf "MD run %s from %s." "$current" "$prevrst"
            $gpu -i ${mdin} -c ${prevrst} -p ${parm} -ref ${ref} -o ${mdout} -r ${mdrst} -x ${mdnc} -inf ${info} &
            $jobname "md${current}_${system}"; wait
            printf "Write-protecting .mdout, .nc, .rst7 files from %s.\n" "$system"
            if [[ -f ${mdnc} ]] && [[ -f ${mdrst} ]] && [[ -f ${mdout} ]]; then
                strip_cpptraj_script "$system" "$path" "$current" 10 0
                chmod -w ${mdout} ${mdrst}
                if [ -f ions.${mdnc} ] && [ -f "${path}/${system}.md${current}.skip10.nc" ]; then
                    rm ${mdnc}
                    chmod -w ${mdrst} ions.${mdnc} ${path}/${system}.md${current}.skip10.nc
                fi
            fi
            sleep 3
            printf "MD run %s of %s complete.\n" "$current" "$system";
        else
            # Should not be necessary now that while loop checks for valid restart and trajectory files.
            printf "Previous restart file not found. Moving on.\n"
        fi
	done
}

vacmin(){
	local path=$1
	local system=$2
	local loops=$3
	local vac_in="${repo}/inFiles/vacmin.in"
	if [[ ! -f ${vac_in} ]]; then
	    local vac_in="ins/vacmin.in"
        if [[ ! -f ${vac_in} ]]; then
            local vac_in="${repo}/inFiles/vacmin.in"
        else
            for input in */*vac*; do
                if [[ -f ${input} ]]; then
                    local vac_in="$input"
                else
                    echo "No input file for vacuum minimization found. Aborting run."
                    exit
                fi
            done
        fi
    fi
    local parm="${path}/${system}.prmtop"
    local leaprst="${path}/${system}.rst7"
    local vac_prefix="${path}/${system}.vacmin"
	for current in `seq 1 $loops`; do
	    prev=$(( current - 1 ))
        local minrst="${vac_prefix}${current}.rst7"
        local vac_out="${vac_prefix}${current}.out"
        local info="${path}/mdinfo"
        if [[ ${current} == 1 ]]; then
            prevrst="$leaprst"
        else
            prevrst="${vac_prefix}${prev}.rst7"
        fi
        printf "Vacuum minimization #${index} of %s.\n" "$system"
        printf "Number of cores per process: %s\n" "$cpu_num"
        if [[ -f ${vac_in} ]] && [[ -f ${parm} ]] && [[ -f ${leaprst} ]]; then
            $sander -O -i ${vac_in} -o ${vac_out} -p ${parm} -c ${prevrst}  -ref ${leaprst} -r ${minrst} -inf ${info} &
            $jobname "${system}_vacmin"; wait
        else
            printf "Files not found. Minimization will not run for %s.\n" "$system"
            exit
        fi
        sleep 3
    done
    local mol_name=${system}
    if [[ $mol_name == *"_vac" ]]; then
        local mol_name=${mol_name%'_vac'}
    fi
    if [[ -f ${minrst} ]]; then
        cpptraj ${path}/${system}.prmtop -y ${minrst} -x ${mol_name}.mol2
    fi
}

### Code for running jobs

job_runner(){
    echo "$@"
    path=$1
    system=$2
    run_type=$3
    loops=$4
    #if [[ "$loops" == "-m" ]]; then
    #    shift 4
    #    method_array=("$@")
    #else
    #    shift 4
    #fi
    if [[ ${run_type} == "amber" ]]; then
        cpu_minimize "$path" "$system" "$loops"; wait
        #amber_run "$path" "$system" "$loops" &
        return 1
    elif [[ ${run_type} == "md" ]]; then
        md "$path" "$system" "$loops" &
        return 1
    elif [[ ${run_type} == "vacmin" ]]; then
        vacmin "$path" "$system" "$loops" &
        return 1
    elif [[ ${run_type} == "method" ]]; then
        printf "Running by list. %s\n" "${method_array}[@]"
        method_loop "$path" "$system" "$ins_dir" "" "" &
    fi
}

# Loops through multiple topologies.
parm(){
	local run_type=$1
	local loops=$2
  local glob_pattern=$3
	shift 3
    for parm in *${glob_pattern}*.prmtop; do
        ((i=i%batch_size)); ((i++==0)) && wait
        if [[ -f "$parm" ]]; then
            local path=${parm/'.prmtop'}
            printf "Running system: %s \n" "$path"
            if [[ ! -d ${path} ]]; then
                mkdir "${path}"
            fi
            local system="$path"
            mv ${system}.* ${path}/
            job_runner "$path" "$system" "$run_type" "$loops" "$@" &
            sleep 5
        fi
    done
}


folder(){
# Serial processing for runs
    local run_type=$1
    local loops=$2
    local glob_pattern="$3"
    shift 3
    for path in *${glob_pattern}*/ ; do
        ((i=i%batch_size)); ((i++==0)) && wait
        local path=${path/'/'}
        if [[ -d "$path" ]] && [[ ! ${path} == "ins" ]]; then
            printf "Running system: %s\n" "$path"
            local system=$path
            job_runner "$path" "$system" "$run_type" "$loops" "$@" &
            sleep 5
        fi
    done
}

current(){
    local run_type=$1
    local loops=$2
    for parm in *.prmtop; do
        if [[ -f ${parm} ]] && [[ ${parm} != "ions.*" ]] && [[ ${parm} != "strip.*" ]]; then
            system=${parm/'.prmtop'}
            job_runner "./" "$system" "$run_type" "$loops"
        fi
    done
}
# Function for setting number of CPUs cores to use.
power2() { echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l; }

###
### SETTINGS FOR MAIN PROGRAM
###
unset run_type; unset loop_type
gpu_list="0,1,2,3,4,5,6,7"
gpu="pmemd.cuda -O"
gpu_count=1
glob_pattern=""
batch_size=999
cpu_num=16
keep_frame_step=10
loops=1
overwrite="False"
while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.

    case $arg in

        -folder)
            loop_type="folder"
            ;;
        -parm)
            loop_type="parm"
            ;;
        -current)
            loop_type="current"
            printf "Running AMBER on system in this directory.\n"
            ;;
        -amber)
            printf "Running minimization, heating, two equilibrations and MD...\n"
            run_type="amber"
            if [[ $1 != "-"* ]]; then
                loops=$1
                shift
            fi
            check_md_inputs 'amber'
            ;;
        -md)
            printf "Running production runs...\n"
            run_type="md"
            if [[ $1 != "-"* ]]; then
                loops=$1
                shift
            fi
            check_md_inputs 'md'
            ;;
        -vacmin)
            printf "Running minimizations in vacuo...\n"
            run_type="vacmin"
            if [[ $1 != "-"* ]]; then
                loops=$1
                shift
            fi
            ;;
        -p)
            glob_pattern=$1
            printf "Running systems containing %s.\n" $glob_pattern
            shift
            ;;
        -gpu)
            if [[ $1 != "-"* ]]; then
                gpu_list=$1
                printf "Using GPUs: %s.\n" "$gpu_list"
                shift
            else
                printf "List of GPUs to use not specified. Using all cards by default.\n"
            fi
            ;;
        -multi)
            if [[ $1 != "-"* ]]; then
                gpu_count=$1
                printf "Running each job on %s GPUs.\n" "$gpu_count"
                shift
            else
                printf "Number of GPUs to use not given.\n"
                printf "Using 2 GPU cards by default.\n"
                gpu_count=2
            fi
            gpu="mpirun -np ${gpu_count} pmemd.cuda.MPI -O"
            ;;
        -b)
            batch="True"
            if [[ $1 != "-"* ]]; then
                batch_size=$1
                cpu_num=`power2 $(( 32/batch_size ))`
                printf "Using %s CPU cores for minimizing.\n" "$cpu_num"
                shift
            fi
            ;;
        -k)
            if [[ $1 != "-"* ]]; then
                keep_frame_step=$1
                shift
            fi
            ;;
        -O)
            overwrite="True"
            ;;
        -types) # Specify run names (eg. heat, equil1, md, etc)
            while [[ $1 != "-"* ]]; do
                method_array+=("$1")
                printf " $1 "
                shift
            done
            printf "Using these run types: %s\n" "${method_array[@]}"
            run_type="method"
            ;;
        esac
done

debug_check_progress="True"
### Aliases for AMBER executables.
cpu="mpirun -np ${cpu_num} pmemd.MPI -O"
sander="$AMBERHOME/bin/sander"
echo "$cpu"
if [[ $gpu_count == 1 ]]; then
    gpu="pmemd.cuda -O"
fi
if [[ -z ${run_type} ]]; then
    printf "No run type (vacmin, amber, md) selected.\n"
elif [[ ${run_type} == "vacmin" ]] && [[ ${batch_size} -eq 999 ]]; then
	batch_size=1
elif [[ ${run_type} != 'amber' ]] && [[ ${batch_size} -eq 999 ]]; then
    printf "Counting topologies to divide CPU cores.\n"
    parm_count=0
    for folder in *"$glob_pattern"*/; do
        if ls "${folder}"*.prmtop 1> /dev/null 2>&1; then
            parm_count=$(( parm_count + 1 ))
        fi
    done
    cpu_num=`power2 $(( 32/parm_count ))`
    echo "Using ${cpu_num} CPU cores for each minimization. Running in batches of ${batch_size}."
fi
cpu="mpirun -np ${cpu_num} pmemd.MPI -O"


if [[ ${loop_type} == "folder" ]]; then
    printf 'Running systems by folder...\n'
    folder "$run_type" "$loops" "$glob_pattern"
elif [[ ${loop_type} == "parm" ]]; then
    printf 'Running systems with .prmtop files in this directory...\n'
    parm  "$run_type" "$loops" "$glob_pattern"
elif [[ ${loop_type} == "current" ]]; then
    printf "Running system in the current directory...\n"
    current "$run_type" "$loops"
else
    printf "No loop type found. Only %s. Scripting ending...\n\n" "$loop_type"
fi