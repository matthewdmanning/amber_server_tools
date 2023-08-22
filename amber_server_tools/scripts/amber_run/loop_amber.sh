#!/bin/scripts
#ssh mdmannin@yygpu#.mse.ncsu.edu
#Copy files into folder
#chmod +x Amber.sh
#nohup ./Amber.sh &> job.log &
#! /bin/scripts

#source /usr/local/apps/amber14/env/amber_run.sh   # use this for GPU 1-4
#source /usr/local/amber14/amber_run.sh   # use this for GPU 5&6
source /usr/local/apps/amber/16.05/amber.sh
echo "AMBERHOME = $AMBERHOME"
echo "PATH = $PATH"
echo "LD_LIBRARY_PATH = $LD_LIBRARY_PATH"
#export CUDA_VISIBLE_DEVICES=0      # this is GPU card number

N=4
cpu_num=$(( 32/N ))
echo "Number of cores per process: $cpu_num"
cpu="mpirun -n ${cpu_num} pmemd.MPI -O"
mgpu="mpirun -n 2 pmemd.cuda.MPI -O"
gpu="pmemd.cuda -O"
jobname='source /home/common/user_jobs/PID_log.sh'
#gpulist="0,1"


while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.

    case $arg in

        --help)
            print_help          # bar takes no arg, doesn't need an extra shift
            ;;
        -full)
            run_type=$1
         -md)
            run_type=$1
		-vacmin)
            run_type=$1
        -nc)
            cpu_num=$1
            shift           # foo takes an arg, needs an extra shift
            ;;    esac
done
### Arguments
run_type=$1

### Function for listing arguments
print_help(){
	echo "Script for executing AMBER jobs. Matthew Manning, 2017."
	echo "Usage: nohup ./loop_amber.sh [OPTIONS] &> [LOGFILE] &"
	echo "	-full						Performs minimization, heating, equil1, equil2, and 1 MD"
	echo "	-md	[RESTART] [RUNS]		Performs RUNS production runs, using md[RESTART].rst7 for initial coords"
	echo "	-vacmin						Performs a sander minimization using vacmin.in as input"
	echo "	-nc							Number of CPU cores to use in minimization. Default is 32."
	echo "	-ng							Number of GPU cards to use. Default is 1."
	echo "	-g [CARDS]					Select GPU card(s) to use for job. Input multiples GPUs as comma-separated list with no spaces. Ex. 1,2"
	echo "	-b [SIZE]					Runs jobs in batches of [SIZE]. Currently, all jobs must finish before next batch starts."
	echo "	-p [PATTERN]				Pattern for selecting which .prmtop files to run."
	echo "	-r							Search subdirectories for jobs to run. Not necessary if -dp flag is used."
	echo "	-dp [PATTERN]				Pattern for selecting directories to run."

	echo "	Arg #2: GPU selection method:  "

### Function for full minimization, heat, and first MD run.
amber(){
	### Get GPU with most resources
	source /usr/local/apps/env/nvidia-smi_sort.sh $gpulist
	echo "Sourcing GPU(s) with most available resources."
	### Start running MD.
	path=$1
	system=$2
	echo "minimization"
	$cpu  -i min.in -o ${path}/min.out -p ${path}/${system}.prmtop -c ${path}/${system}.rst7  -ref ${path}/${system}.rst7 -r ${path}/min.rst7 -inf ${path}/mdinfo &
	$jobname min_$system; wait
	echo "sleeping"
	sleep 10

	echo "heating"
	$cpu -i heat.in -o ${path}/heat.out -p ${path}/${system}.prmtop -c ${path}/min.rst7 -ref ${path}/min.rst7 -r ${path}/heat.rst7 -inf ${path}/mdinfo
	$jobname heat_$system; wait
	echo "sleeping"
	sleep 10
	echo ".."

	echo "MD"
	$gpu -i md.in -c ${path}/.rst7 -p ${path}/${system}.prmtop -ref ${path}/heat.rst7 -o ${path}/md1.out -r ${path}/md1.rst7 -x ${path}/md1.nc -inf ${path}/mdinfo &
	$jobname md1_$system; wait
	echo "sleeping"
	sleep 10
	echo 'MD Complete';
}

### Function for single run of MD, continued from previous MD or heat.
### Arguments: path, system_name, number of input .rst7 file (for MD continuation) and number of times to run loop.
md(){
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
	$cpu -i vacmin.in -o ${path}/vacmin.out -p ${path}/${system}.prmtop -c ${path}/${system}.rst7  -ref ${path}/${system}.rst7 -r ${path}/${system}_min.rst7 -inf ${path}/mdinfo &
	$jobname vacmin_$system; wait
	echo "sleeping"
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



for path in */ ; do
	#if [[ $path == *"-01M"* ]]; then
	((i=i%N)); ((i++==0)) && wait
	path=${path%'/'}
	echo $path
	system=$path
	if [[ $run_type == 'full' ]]; then
		amber "$path" "$system" &
	elif [[ $run_type == 'vacmin' ]]; then
		vacmin "$path" "$system" &
	elif [[ $run_type == 'md' ]]
		md "$path" "$system" "$start" "$loops"
	sleep 5
	#fi
done
echo "Task(s) completed."
