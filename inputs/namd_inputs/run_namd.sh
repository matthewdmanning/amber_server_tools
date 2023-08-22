#!/usr/bin/env scripts
# Script for running MD simulations using NAMD

source /usr/local/apps/env/tcllib.tcl
module load namd/2.12_cuda

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
	local system=$1
	local path=$2
	local md_num=$3
	local keep_frame_step=$4
	local strip_ions=$5

    local trajin="${path}/traj.in"
	local in_traj="${path}/${system}.md${md_num}.nc"
    local skip_traj="${path}/${system}.md${md_num}.skip${keep_frame_step}.nc"
    local stripped_traj="${path}/${prefix}.${system}.md${md_num}.nc"
    #Load topology and trajectory files.
	printf "parm %s.prmtop\n" "${system}" > $trajin
	printf "trajin %s\n" "$in_traj" >> $trajin
	# Center coords around first molecule. Output every 10th frame with all atoms, including solvent."
    printf "autoimage\n" >> $trajin
	printf "trajout %s offset %s\n" "$skip_traj" "$keep_frame_step" >> $trajin
	printf "run\n" >> $trajin
	# Strip trajectory of water [and ions] and output every frame.
	if [[ $strip_ions == 1 ]]; then
	    local prefix=strip
		printf "strip :WAT,Na+,Cl- outprefix strip\n" >> $trajin
    else
        local prefix=ions
		printf "strip :WAT outprefix ions\n" >> $trajin
	fi
    printf "trajout %s\n" "$stripped_traj">> $trajin
	printf "run\n" >> $trajin
	printf "quit\n" >> $trajin
	cpptraj -i $trajin
	if [[ -f "$stripped_traj" ]] && [[ -f "$skip_traj" ]]; then
	    rm "$in_traj"
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

insert_pbc_info(){
    local system="$1"
    local namd_conf="$2"
    local indir="$3"
    printf "%s %s %s\n" "$1" "$2" "$3"
    echo "VMD output"
    local minmaxcenter=`vmd -dispdev text ${system}.{prmtop,rst7} -e ${indir}/measure_minmax_center.tcl | grep 'Output:' | awk '{print $2,$3,$4}'`
    echo "${minmaxcenter}"
    #local minmaxcenter=$(vmd -dispdev text system.{prmtop,rst7} -e indir/measure_minmaxcenter.tcl | grep 'Output:' | awk '{print $2,$3,$4}');wait
    #echo "${minmaxcenter}"
    sed -i "
    s/cellBasisVector1\t\t0 0 0/cellBasisVector1\t\t$(echo "${minmaxcenter}" | sed -n '1p')/;
    s/cellBasisVector2\t\t0 0 0/cellBasisVector2\t\t$(echo "${minmaxcenter}" | sed -n '2p')/;
    s/cellBasisVector3\t\t0 0 0/cellBasisVector3\t\t$(echo "${minmaxcenter}" | sed -n '3p')/;
    s/cellOrigin\t\t\t\t0 0 0/cellOrigin\t\t\t\t$(echo "${minmaxcenter}" | sed -n '4p')/;
    " "$namd_conf"; wait
    grep cell "$namd_conf"
    return
}

method_loop(){
    printf "Starting method loop.\n"
    local path=$1
	local system=$2
	# Make local copy of NAMD amber_inputs for `sed` later.
    local parent_ins="namd_inputs"
    cp -r "${parent_ins}" "${path}"
    local ref=$4
    local prev_method=$5
    method_array=( prod_vac )
    # Change into system parent directory.
	cd "$path"
    local ins_dir="namd_inputs"
    for list_num in `seq ${#method_array[@]}`; do
		method_num=$(( list_num-1 ))
        local current_method="${method_array[method_num]}"
        current_method_dir="${system}_${current_method}"
        if [[ ! -d ${current_method_dir} ]]; then
			mkdir "${current_method_dir}"
        fi
        local namd_in="${ins_dir}/${current_method}.conf"
        local namd_out="${current_method_dir}/${system}_${current_method}.log"
        # Get input file for this run.
        if [[ ! -f ${namd_in} ]]; then
            printf 'NAMD input file not found. Ending this run.\n'
            return 0
        fi
		if [[ ${method_num} -eq 0 ]] && [[ -z ${prev_method} ]]; then
			printf "Inserting PBC info into %s.\n" "${namd_in}"
			insert_pbc_info "${system}" "${namd_in}" "${ins_dir}"
		elif [[ ${method_num} -gt 0 ]]; then
			local previous_num=$(( method_num-1 ))
			local previous_method="${method_array[previous_num]}"
			local previous_dir="${system}_${previous_method}"
        elif [[ ${method_num} -eq 0 ]] && [[ ! -z ${prev_method} ]]; then
			local previous_method="${prev_method}"
			local previous_dir="${system}_${previous_method}"
		fi
		continuing_job "${system}" "${previous_method}" "${current_method}" "${namd_in}" "${namd_out}"
    done
	cd ..
}

continuing_job(){

	local system="$1"
	local previous_method="$2"
	local current_method="$3"
	local namd_in="$4"
	local namd_out="$5"
	local current_method_dir="${system}_${current_method}"
	if [[ ! -d ${current_method_dir} ]]; then
		mkdir "${current_method_dir}"
	fi
	# Get input file for this run.
	if [[ ! -f ${namd_in} ]]; then
		printf 'NAMD input file not found. Ending this run.\n'
		return 0
	fi
	# Replace placeholder names for input files in NAMD .conf file.
	printf "Next run type is %s.\n" "${current_method}"
	# Replace placeholders in NAMD .conf file.
	sed -i "s/system_name/${system}/g" "${namd_in}"
	sed -i "s/previous_run/${previous_method}/g" "${namd_in}"
	sed -i "s/current_run/${current_method}/g" "${namd_in}"
	namd2 +p8 +devices 0 "${namd_in}" > "${namd_out}" &
	$jobname "${current_method}_${system}"; wait
}

### Function for single run of MD, continued from previous MD or heat.
### Arguments: path, system_name, number of input .rst7 file (for MD continuation) and number of times to run loop.
prod(){
	local path=$1
	local system=$2
	local loops=$3
	local start=$4

    # Identify the first valid restart file, where the next trajectory does not exist.
#    if [[ -z "$start" ]]; then
#        local start=1
#        local next=2
#        while [[ ! -f ${path}/${system}.md${start}.rst7 ]] || [[ -f ${path}/${system}.md${next}.nc ]] || [[ -f ${path}/ions.${system}.md${next}.nc ]] || [[ -f ${path}/${system}.md${next}.skip10.nc ]]; do
#            if $debug_progress_check; then
#                if [[ ! -f ${path}/${system}.md${start}.rst7 ]]; then
#                    printf "Restart file does not exist. %s\n" "$start"
#                elif [[ -f ${path}/${system}.md${next}.nc ]]; then
#                    printf "Original trajectory exists. %s\n" "$next"
#                elif [[ -f ${path}/ions.${system}.md${next}.nc ]]; then
#                    printf "Stripped trajectory exists. %s\n" "$next"
#                elif [[ -f ${path}/${system}.md${next}.skip10.nc ]]; then
#                    printf "Skip trajectory exists. %s\n" "$next"
#                else
#                    printf "We could stop here. %s\n" "$start"
#                fi
#            fi
#            start=$(( start + 1))
#            next=$(( start + 1 ))
#            printf "$start"
#            if [[ ${start} -gt 100 ]]; then
#                printf "No valid restart file found for %s. Terminating run.\n\n" "$system"
#                return 0
#            fi
#        done
#    else
#    	 local next=$(( start + 1 ))
#   	 echo "$next"
#	fi
    printf "First restart found is %s. Starting run #%s.\n" "$start" "$next"

	for i in `seq 1 $loops`; do
	    local prev=$(( start + i - 1 ))
		local current=$(( prev + 1 ))

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
                strip_cpptraj_script
            if [[ -f ${mdnc} ]] && [[ -f ${mdrst} ]] && [[ -f ${mdout} ]]; then
                strip_cpptraj_script "$path" "$system" "$current" 10 0
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

job_runner(){
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
    #if [[ ${run_type} == "method" ]]; then
    #    method_loop "$path" "$system" "namd_inputs" "${system}.pdb"; wait
    #    return 1
    if [[ ${run_type} == "md" ]]; then
        md "$path" "$system" "$loops" &
        return 1
    elif [[ ${run_type} == "method" ]]; then
        printf "Method run.\n"
        printf "Running by list. %s\n" "${method_array}[@]"
        method_loop "$path" "$system" "$ins_dir" "" "min" &
    fi
}

parm(){
	local run_type="$1"
	local loops="$2"
    local glob_pattern="$3"
    local file_type="$4"
	shift 4
    for parm in *"${glob_pattern}"*."${file_type}"; do
        ((i=i%batch_size)); ((i++==0)) && wait
        if [[ -f "$parm" ]]; then
            printf
            local path=${parm/file_type}
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
    for path in *"${glob_pattern}"*/ ; do
        ((i=i%batch_size)); ((i++==0)) && wait
        local path=${path/'/'}
        if [[ -d "$path" ]] && [[ ${path} != "ins" ]]; then
            printf "Running system: %s\n" "$path"
            local system=$path
            echo "$path" "$system" "$run_type" "$loops" "$@" &
            job_runner "$path" "$system" "$run_type" "$loops" "$@" &
            sleep 5
        fi
    done
}

current(){
    local run_type=$1
    local loops=$2
    for parm in *.prmtop; do
        if [[ -f ${parm} ]] && [[ ${parm} != "ions.*" ]] && ${parm} != "strip.*" ]]; then
            system=${parm/'.prmtop'}
            job_runner "./" "$system" "$run_type" "$loops"
        fi
    done
}
# Function for setting number of CPUs cores to use.
power2() { echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l; }

### Displays name of job on server and Cacti.
if [[ -f /home/common/user_jobs/PID_log.sh ]]; then
    jobname='source /home/common/user_jobs/PID_log.sh'
else
    `echo "No PID_log.sh file found."`
    jobname="wait;"
fi

namd_cpu(){
    local input_file="$1"
    local output_file="$2"
    local job_name="$3"
    local num_cores="$4"

    if [[ ! -z ${num_cores} ]] && [[ ${num_cores} -gt 1 ]]; then
        local cores="+p${num_cores}"
    else
        local cores=""
    fi

    namd2 "$cores" "$input_file" > "$output_file" &
    $job_name; wait
    return 1
}

gpu_list="0,1,2,3,4,5,6,7"
gpu="pmemd.cuda -O"
gpu_count=1
glob_pattern=""
batch_size=9
cpu_num=16
keep_frame_step=10
loops=1
overwrite="False"
#

while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.

    case $arg in

        -folder)
            loop_type="folder"
            ;;
        -amber)
            printf "Using AMBER *.prmtop and *.rst7 inputs.\n"
            input_type="amber"
            ;;
        -current)
            loop_type="current"
            printf "Running AMBER on system in this directory.\n"
            ;;
        -method)
            run_type="method"
            ;;
        -md)
            printf "Running production runs...\n"
            run_type="prod"
            if [[ $1 != "-"* ]]; then
                loops=$1
                shift
            fi
            ;;
        -vacmin)
            printf "Running minimizations in vacuo...\n"
            run_type=vacmin
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

if [[ ${run_type} == "vacmin" ]] && [[ ${batch_size} == 999 ]]; then
	batch_size=1
fi

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
    printf "No run type found. Only %s. Scripting ending...\n\n" "$run_type"
fi
