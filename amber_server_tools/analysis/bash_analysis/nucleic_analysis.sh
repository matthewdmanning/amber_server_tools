#!/usr/bin/env scripts

rog_window() {

nucleic_start=$1
nucleic_stop=$2
window_size=$3
traj_input=$4
rog_file=$5

nucleic_length=$(( (nucleic_stop - nucleic_start + 1) / 2 ))
number_of_windows=$(( nucleic_length - window_size + 1 ))



for window in $( seq 1 number_of_windows ); do
    first_start=$(( nucleic_start + window - 1 ))
    first_stop=$(( first_start + window_size - 1 ))
    second_stop=$(( nucleic_stop - window + 1 ))
    second_start=$(( second_stop - window_size + 1 ))
    printf "radgyr rog_%s-%s :%s-%s,%s-%s out %s\n" "$first_start" "$first_stop" "$first_start" "$first_stop" "$second_start" "$second_stop" "$rog_file"  >> "${traj_input}"
done

}

basepair_com(){

nucleic_start=$1
nucleic_stop=$2
traj_input=$3
com_filename=basepair_com.dat
nucleic_length=$(( (nucleic_stop - nucleic_start + 1) / 2 ))

for index in $(seq 1 nucleic_length); do
    first_res=$(( nucleic_start + index - 1 ))
    second_res=$(( nucleic_stop - index + 1 ))
    printf 'vector com_%s center :%s,%s out %s\n' "$index" "$first_res" "$second_res" "$com_filename" >> "${traj_input}"
done
}

simple_com(){

mask=$1
traj_input=$2
simple_com_filename=$3

    printf 'vector com_%s center %s out %s\n' "$index" "$mask" "$simple_com_filename" >> "${traj_input}"
}

distance_com(){

nucleic_start=$1
nucleic_stop=$2
mask=$3
traj_input=$4
distance_filename=distance_com.dat
nucleic_length=$(( (nucleic_stop - nucleic_start + 1) / 2 ))

for index in `seq 1 $nucleic_length`; do
    first_res=$(( nucleic_start + index - 1 ))
    second_res=$(( nucleic_stop - index + 1 ))
    printf 'vector com_nucleic_%s mask :%s,%s %s magnitude out %s\n' "$index" "$first_res" "$second_res" "$mask" "$distance_filename" >> "${traj_input}"
    printf 'vectormath vec1 com_nucleic_%s vec2 %s out %s\n' "$index" "$mask_com_vec" "$distance_filename" >> "${traj_input}"
done


}

minimum_dist(){

nucleic_start=$1
nucleic_stop=$2
mask=$3
traj_input=$4
distance_filename=min_distance.dat
nucleic_length=$(( (nucleic_stop - nucleic_start + 1) / 2 ))

for index in $(seq 1 nucleic_length); do
    first_res=$(( nucleic_start + index - 1 ))
    second_res=$(( nucleic_stop - index + 1 ))
    printf 'vector com_nucleic_%s mask %s :%s,%s magnitude out %s\n' "$index" "$mask" "$first_res" "$second_res" "$distance_filename" >> "${traj_input}"
done

}

#e2e(){}

run_glob(){
start_res=$1
stop_res=$2
window_size=$3
mask2=$4

for folder in */; do
    path=${folder/'/'}
    system=$path
    traj_input=$path/traj.in
    rog_file=rog_window.${system}.dat
    rog_window "$start_res" "$stop_res" "$window_size" "$traj_input" "$rog_file"
    #basepair_com "$start_res" "$stop_res" "$traj_input"
    #distance_com "$start_res" "$stop_res" "$mask2" "$traj_input"
    minimum_dist "$start_res" "$stop_res" "$mask2" "$traj_input"
    #simple_com "$mask2" "$traj_input" "au_core_com.dat"
    printf "run\n" >> "${traj_input}"
    printf "quit\n" >> "${traj_input}"
done
}

printf "What is the residue number of the first nucleic acid?\t"
read -r start_res
printf "What is the residue number of the last nucleic acid?\t"
read -r stop_res

printf "How long should the rolling window be?\t"
read -r window_size
printf "What is the mask for the second group of atoms?\t"
read -r mask2

run_glob "$start_res" "$stop_res" "$window_size" "$mask2"