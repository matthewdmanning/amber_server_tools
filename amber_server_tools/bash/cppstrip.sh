#!/bin/bash
# Script for moving files


foldlist="1/Thiols","1/dnaLigands"
#foldlist=("9/50x12-60ratio4densehexylamine")
m="/home/mdmannin/mnt"
storage="/media/mdmannin/Storage"
step=10
ionstrip=0

if [ ionstrip==1 ]; then prefix="strip"; else prefix="ions"; fi
current=`pwd`
trajin="${current}/trajin"
echo > $trajin
for fold in "${foldlist[@]}"
	do
	gpuPath="${m}${fold}"
	cut=${fold%"%/"}
	store="${storage}/${cut}"
	cd $gpuPath
	pwd
	for name in */ ; do	
		name=${name%"/"}
		ParmPath="${gpuPath}/${name}"
		echo "Calling folder $ParmPath"
		store="${stodir}/${name}"
		traj="md5.nc"
		if [ -f "${ParmPath}/${traj}" ] && [ ! -f "${store}/${prefix}.${traj}" ]; then
			echo "Stripping ${ParmPath}/${traj} \n"
			if [ ! -d "${store}" ]; then mkdir $store; fi
			echo "parm ${ParmPath}/${name}.prmtop">> $trajin
			echo "trajin ${ParmPath}/${traj} 1 last $step" >> $trajin
			echo "strip :WAT" >> $trajin
			if [ $ionstrip==1 ]; then echo "strip @Na+,Cl-" >> $trajin; fi
			echo "parmwrite out ${store}/${prefix}.${name}.prmtop" >> $trajin
			echo "trajout ${store}/${prefix}.${traj}" >> $trajin
			echo "clear all /n" >> $trajin
			parmlist+=("${ParmPath}/${name}.prmtop")
			namelist+=("${name}")
			trajlist+=("${ParmPath}/${traj}")
			stripparmlist+=("${store}/${prefix}.${name}.prmtop")
			striptrajlist+=("${store}/${prefix}.${traj}")
			storelist+=("$store")
		fi
	done
done
echo ${storelist[@]}
echo "quit" >> trajin
cd $current
chmod +x $trajin
#cpptraj -i $trajin
finished=0
if [ finished==1 ]; then
	for j in `seq ${#foldlist[@]}`
		do
		i=$((j-1))	
		chmod 444 ${stripparmlist[${i}]}
		chmod 444 ${striptrajlist[${i}]}
		newparm="${storelist[${i}]}/${namelist[${i}]}.prmtop"
		if [ ! -f "$newparm" ]; then
			cp ${parmlist[${i}]} $newparm
			chmod 444 $newparm
			#rm ${parmlist[${i}]}
		fi
		newtraj="${storelist[${i}]}/${namelist[${i}]}.nc"
		if [ ! -f "$newparm" ]; then
			cp ${trajlist[${i}]} $newtraj
			chmod 444 $newtraj
			#rm ${trajlist[${i}]}
		fi
	done
fi

