#!/usr/bin/env scripts
##### Automated script for running AMBER jobs. #####
##### 		Created by: Matthew Manning		   #####
#####				August 3, 2016			   #####





	#Default arguments

	#mgpu="mpirun -n 2 pmemd.cuda.MPI -O"
	#gpulist="0,1"



#cpu_num=$(( 32/N ))
#echo "Number of cores per process: $cpu_num"


### Function for listing arguments
print_help(){
	echo "Script for executing AMBER jobs. Matthew Manning, 2017."
	echo "Usage: nohup ./loop_amber.sh [OPTIONS] &> [LOGFILE] &"
	echo "	-full						Performs minimization, heating, equil1, equil2, and 1 MD"
	echo "	-md	[RESTART] [RUNS]		Performs RUNS production runs, using md[RESTART].rst7 for initial coords"
	echo "	-vacmin						Performs a sander minimization using vacmin.in as input"
	echo " 	-O							Overwrite existing files. Default is no."
	echo "	-nc							Number of CPU cores to use in minimization. Default is 32."
	echo "	-ng							Number of GPU cards to use. Default is 1."
	echo "	-g [CARDS]					Select GPU card(s) to use for job. Input multiples GPUs as comma-separated list with no spaces. Ex. 1,2"
	echo "	-b [SIZE]					Runs jobs in batches of [SIZE]. Currently, all jobs must finish before next batch starts."
	echo "	-p [PATTERN]				Pattern for selecting which .prmtop files to run."
	echo "	-r							Search subdirectories for jobs to run. Not necessary if -dp flag is used."
	echo "	-dp [PATTERN]				Pattern for selecting directories to run."
	echo " 	-V							Verbose output of .mdin parameters."
	echo " 	-s [STEP]					Strips restart files and every [STEP] frame of trajectory of :WAT,Na+,Cl-."
	echo " 	-ions [STEP]				Strips restart files and every [STEP] frame of trajectory of :WAT, leaving ions."
}
### Function for full minimization, heat, and first MD run.
run_amber(){
	run_type=$1
	mdin=$2
	mdout=$3
	parm=$4
	coords=$5
	ref=$6
	rst=$7
	nc=$8
	info=$9
	job=$10

	# Print mdin file if Verbose is specified.
	if [ $verbose=="True" ]; then
		less ${mdin}
	fi

	# Check for incoming files. Print error if file does not exist.
	if [ -f ${mdin} -a -f ${parm} -a -f ${coords} -a -f ${ref} ]; then
		echo ".mdin, .prmtop, .rst7, and -ref files all found."
	else
		echo "One of .mdin, .prmtop, .rst7, and -ref files not found. Shutting down this loop."
		break
	fi

	if [ ${overwrite}=="False" ] && [ -f ${mdout} -o -f ${rst} -o -f ${nc} ]; then
		echo "Output file(s) (.out, .rst7. or .nc) already exists and -O overwrite is not specified. Shutting down this loop."
		break
	else [ ${overwrite}=="True" ] && [ -f ${mdout} -o -f ${rst} -o -f ${nc} ]
		echo "Output file(s) (.out, .rst7. or .nc) already exists. Overwriting existing file(s)."
	fi

	if [ "$nc"==0 ]; then
		$run_type -i ${mdin} -o ${mdout} -p ${parm} -c ${coords} -ref ${ref} -r ${rst} -inf ${info} &
		$jobname ${job}; wait
	else
		${run_type}  ${mdin} -o ${mdout} -p ${parm} -c ${coords} -ref ${ref} -r ${rst} -x ${nc} -inf ${info} &
		$jobname ${job}; wait
		chmod -w ${nc}
	fi

	if [ "$strip" -gt 0]; then
		cpptraj_strip ${parm} ${rst} 0 ${strip_frame}
	else [ "$ions" -gt 0 ]
		cpptraj_strip ${parm} ${rst} 1 ${ions_frame}
	echo "Write-protecting .mdout, .rst7 abd .nc files."
	chmod -w ${mdout} ${rst}
	sleep 3
	echo ".."
	fi
}

amber(){
	### Get GPU with most resources
	if [ $cards=="auto" ]; then
		source /usr/local/apps/env/nvidia-smi_sort.sh $gpulist
		echo "Sourcing GPU(s) with most available resources."
	fi
	### Check for Thermostating Methods to use correct mdin files.
	minin="min.pme.mdin"
	if [ -f "md.weak.pme.mdin" ]; then
		thermostat_type="weak"
	else [ -f "md.lang.pme.mdin" ]
		thermostat_type="lang"
	fi

	### mdin names
	heatin="heat.${thermostat_type}.pme.mdin"
	eq1in="equil1.${thermostat_type}.pme.mdin"
	eq2in="equil2.${thermostat_type}.pme.mdin"
	mdin="md.${thermostat_type}.pme.mdin"

	### mdout names
	minout="${path}/${system}.min.out"
	heatout="${path}/${system}.heat.out"
	eq1out="${path}/${system}.equil1.out"
	eq2out="${path}/${system}.equil2.out"
	md1out="${path}/${system}.md1.out"

	### Trajectory names
	md1nc="${path}/${system}.md1.nc"

	### Restart names
	leaprst="${path}/${system}.rst7"
	minrst="${path}/${system}.min.rst7"
	heatrst="${path}/${system}.heat.rst7"
	eq1rst="${path}/${system}.equil1.rst7"
	eq2rst="${path}/${system}.equil2.rst7"
	md1rst="${path}/${system}.md1.rst7"

	### prmtop name
	parm="${path}/${system}.prmtop"

	### mdinfo name
	info="${path}/mdinfo"


	echo "Starting Minimization of ${system}..."
	run_amber $cpu ${minin} ${minout} ${parm} ${leaprst} ${leaprst} ${minrst} ${info} "${system}_min" &
	sleep 3
	echo ".."

	echo "Starting Heating of ${system}..."
	run_amber $mgpu ${heatin} ${heatout} ${parm} ${minrst} ${minrst} ${heatrst} ${info} "${system}_heat" &

	echo "Starting Equilibration #1 of ${system}..."
	run_amber $mgpu ${eq1in} ${eq1out} ${parm} ${heatrst} ${heatrst} ${eq1rst} ${info} "${system}_equil1" &

	echo "Starting Equilibration #2 of ${system}..."
	run_amber  $mgpu ${eq2in} ${eq2out} ${parm} ${eq1rst} ${heatrst} ${eq2rst} ${info} "${system}_equil2" &

	echo "Starting MD Run #1 of ${system}..."
	run_amber  $mgpu ${mdin} ${eq2rst} ${parm} ${eq2rst} ${md1out} ${md1rst} ${md1nc} ${info} "${system}_md1" &

	echo "Keeping every ${keep_frame_step} frames with all solvent."
	echo "Stripping trajectory..."
	strip_cpptraj_script "$parm" "$file" 1 "$keep_frame_step" 0 &
	echo "Write-protecting .mdout and .rst7 files."
	chmod -w ${md1out} ${md1rst}
	sleep 3
	echo 'MD Run #1 Complete';
}

strip_cpptraj_script(){
	parm=$1
	file=$2
	keep_ions=$3
	keep_frame_step=$4

	echo "parm ${parm}" > traj.in
	echo "trajin ${path}/${system}.md${md_num}.nc 1 last" >> traj.in
	echo "trajout ${path}/${system}.md${md_num}.${keep_frame_step}step.nc"
	if [[ $strip_ions == 1 ]]; then
		echo "strip :WAT,Na+,Cl- outprefix strip" >> traj.in
		echo "trajout strip.${path}/${system}.md${md_num}.nc"
	else
		echo "strip :WAT outprefix ions" >> traj.in
		echo "trajout ions.${path}/${system}.md${md_num}.nc"
	fi
	echo "run" >> traj.in
	echo "quit" >> traj.in
}

### Function for single run of MD, continued from previous MD or heat.
### Arguments: path, system_name, number of input .rst7 file (for MD continuation) and number of times to run loop.
prod_run(){
	path=$1
	system=$2
	# Take third argument as previous md?.rst7 value. If not set, default to previous=1.
	prev=${3:1}
	# Take fourth argument as number of MD runs. If not set, default to loops=1.
	loops=${4:1}
	for i in `seq $loops`; do
		source /usr/local/apps/env/nvidia-smi_sort.sh $gpulist
		current=$(( prev += 1 ))
		echo "MD Run ${current} from md${prev}.rst7."
		$gpu -i md.in -c ${path}/md${prev}.rst7 -p ${path}/${system}.prmtop -ref ${path}/md${prev}.rst7 -o ${path}/md${current}.out -r ${path}/md${current}.rst7 -x ${path}/md${current}.nc -inf ${path}/mdinfo &
		$jobname md${current}_$system; wait
		echo "sleeping"
		sleep 10
		echo 'MD Run ${current} Complete';
		prev=$(( prev += 1 ))
	done

}

vacmin(){
	path=$1
	system=$2
	echo "minimization"
	echo $(ls)
	amber_run ${cpu} "${path}/${system}.vacmin.out" "${path}/${system}.prmtop" "${path}/${system}.rst7" "${path}/${system}.rst7" "${path}/${system}_min.rst7" "${path}/mdinfo" "${system}_vacmin" &
	sleep 10
}
#prod_loop(){
	#for j in `seq $1 $2`; do
		#i=$j-1
		#if [[ $j == 2 ]]; then
			#i=''
		#fi
		#source /usr/local/apps/env/nvidia-smi_sort.sh $gpulist
		#echo "MD Run ${j}"
		#$gpu -i md.in -c ${path}/md${i}.rst7 -p ${path}/${system}.prmtop -ref ${path}/md${i}.rst7 -o ${path}/md${j}.out -r ${path}/md${j}.rst7 -x ${path}/md${1}.nc -inf ${path}/mdinfo &
		#$jobname md${j}_$system; wait
		#echo "sleeping"
		#sleep 10
		#echo 'MD Run ${j} Complete';
	#done
#}
### Example of running FOR loop in blocks
#for thing in a b c d e f g; do
   #((i=i%N)); ((i++==0)) && wait
   #task "$thing" &
#done
batch_size=1
gpu="pmemd.cuda"
jobname='source /home/common/user_jobs/PID_log.sh'
file_pattern="*"
dir_pattern="*"
verbose="False"
strip_step=1
ions_step=1
keep_ions="True"
while [[ $1 = -* ]]; do
arg=$1; shift           # shift the found arg away.

case $arg in

	--help)
		print_help
		break
		;;
	-full)
		run_type="$1"
		;;
	-md)
		run_type="$1"
		prev="$2"
		loops="$3"
		shift;shift
		;;
	-vacmin)
		run_type="$1"
		;;
	-nc)
		cpu_num="$1"
		"mpirun -np ${cpu_num} pmemd.MPI"
		shift
		;;
	-ng)
		gpu_num="$1"
		if [ "$gpu_num" -gt 1]; then
			gpu="mpirun -np ${gpu_num} pmemd.cuda.MPI"
		fi
		shift
		;;
	-g)
		cards="$1"
		shift
		;;
	-b)
		batch="True"
		batch_size="$1"
		shift
		;;
	-p)
		prmtop_pattern="$1"
		shift
		;;
	-r)
		recursive="True"
		;;
	-dp)
		dir_pattern="$1"
		shift
		;;
	-V)
		verbose="True"
		;;
	-O)
		overwrite="True"
		;;
	-s)
		strip_frame="$1"
		keep_ions="False"
		shift
		;;
	-ions)
		ions_frames="$1"
		shift
		;;    esac
done

if [ $overwrite=="True" ]; then
	cpu="${cpu} -O"
	gpu="${gpu} -O"
fi


	logfile=job.log
	exec > $logfile 2>&1

	working_dir=`pwd`

	source /usr/local/apps/amber/16.05/amber.sh
	echo "AMBERHOME = $AMBERHOME"
	echo "PATH = $PATH"
	echo "LD_LIBRARY_PATH = $LD_LIBRARY_PATH"\

	if [ "$recursive" == "True" ]; then
		for path in */ ; do
			if [ "$path" == *"$dir_pattern"* ]; then
				((i=i%batch_size)); ((i++==0)) && wait
				path=${path%'/'}
				echo $path
				system=$path
				if [[ $run_type == 'full' ]]; then
					amber "$path" "$system" &
				elif [[ $run_type == 'vacmin' ]]; then
					vacmin "$path" "$system" &
				elif [[ $run_type == 'md' ]]; then
					prod_run "$path" "$system" "$start" "$loops"
				sleep 5
				fi
			fi
		done
	else
		for path in *.prmtop; do
			if [ "$path" == "$file_pattern" ]; then
				((i=i%batch_size)); ((i++==0)) && wait
				path=${path%'/'}
				echo "$path"
				system=$path
				if [ ! -d "$path" ]; then
					mkdir "$path"
				fi
				mv ${system}.* ${path}/
				if [[ $run_type == 'full' ]]; then
					amber "$path" "$system" &
				elif [[ $run_type == 'vacmin' ]]; then
					vacmin "$path" "$system" &
				elif [[ $run_type == 'md' ]]; then
					prod_run "$path" "$system" "$start" "$loops"
				sleep 5
				fi
			fi
		done
	echo "Task(s) completed."
	fi
