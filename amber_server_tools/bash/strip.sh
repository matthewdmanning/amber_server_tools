#!/bin/bash

for path in */; do
	cd $path
	system=${path/'/'}
	echo "parm ${system}.prmtop" > traj.in
	traj_num=1
	while [ -f "${system}.md${traj_num}.nc" ]; do
		echo "trajin ${system}.md${traj_num}.nc" >> traj.in
		traj_num=$((traj_num +=1))
	done
	latest_traj_num=$((traj_num - 1))
	echo "strip :WAT outprefix ions" >> traj.in
	if [ ${lastest_traj_num} > 1 ]; then
		echo "trajout ions.${system}.md1-${latest_traj_num}.nc" >> traj.in
	else
		echo "trajout ions.${system}.md1.nc" >> traj.in
	fi
	echo "run" >> traj.in
	echo "quit" >> trajin
	cpptraj -i traj.in
	cd ..
done
