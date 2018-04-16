#!/bin/bash

e2e() {
file_name=$1
start_residue=$2
end_residue=$3
frame_offset=$4

}

data_slimmer(){


frame_offset=$1
frame_start=$2
output_prefix=${3:skip}
file_name_list=$4
echo $file_name_list
output_name=${output_prefix}.${file_name}
echo $frame_start
modulo=$((frame_start += 1))
a_command="NR == 1 || NR % $frame_offset  == $modulo"
echo $a_command
awk "$a_command" $file_name > $output_name
}

data_slimmer_list(){


frame_offset=$1
frame_start=$2
output_prefix=${3:skip}
file_name_list=( $@ )
echo $file_name_list
for file_name in "${file_name_list[@]}"; do
    output_name=${output_prefix}.${file_name}
    echo $frame_start
    modulo=$((frame_start += 1))
    a_command="NR == 1 || NR % $frame_offset  == $modulo"
    echo $a_command
    awk "$a_command" $file_name > $output_name
done
}


# Script for distance analysis

#echo "Calling directory $d"
#inTop=`echo order*.prmtop`
#inTraj=`echo md*.nc`
#echo "$inTop"
#echo $inTraj
#echo "parm $inTop" > cpptraj_strip.in # '>' overwrites file
#echo "trajin $inTraj" >> cpptraj_strip.in # '>>' adds to files
#
#echo "strip :WAT outprefix ions" >> cpptraj_strip.in
#echo "trajout ions.$inTraj" >> cpptraj_strip.in
#
#echo "resinfo" >> cpptraj_strip.in
#
#cpptraj<cpptraj_strip.in # '<' arg for cpptraj


#echo "Enter first and last ligand resnum."
##read beginning end
#
#
#echo "parm ions.order.*" > cpptraj_dist.in # '>' overwrites file
#echo "trajin ions.md.*" >> cpptraj_dist.in # '>>' adds to files
#
#for i in `seq 2 98`;
#do
##resNum=`echo "$(($i*11))"`
#echo "distance pho$i :$i@S1 :$i@C13 out etoe-pho.dat" >> cpptraj_dist.in # Measure EtoE in hydrophobic
#echo "distance phi$i :$i@S1 :$i@N13 out etoe-phi.dat" >> cpptraj_dist.in # Measure EtoE in hydrophobic
#
##echo "distance $i :$i@S12 :$i@N18 out etoe.dat" >> cpptraj_dist.in # Measure EtoE in charged
##echo "angle $resNum :$resNum@C1 :$resNum@N18 :$resNum@C25 out angle-e1-mid-e2.dat" >> cpptraj_dist.in
#done
#
#cpptraj < cpptraj_dist.in # '<' arg for cpptraj
