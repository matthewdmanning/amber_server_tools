#!/bin/scripts
# Script for moving files to GPU

sourcedir="/home/mdmannin/Desktop/Nanoparticles/RoughNanorods/ParmFiles/"
destindir="/home/mdmannin/mnt6/"

if [[ ! -d $destindir ]]; then
	mkdir $destindir
	echo "Creating directory: $destindir"
fi


cd $sourcedir
pwd

#Avoids *.* display when no files are present.
shopt -s nullglob
for f in *.prmtop; do
	echo $f
	if [[ $f==*.prmtop ]]; then
		echo "Transferring ${f}"
		name=${f%'.prmtop'}
		newPath="$destindir$name/"
		echo $newPath
		if [ ! -d $newPath ]; then
			mkdir $newPath
		fi
		if [ -f "$newPath${name}.prmtop" ]; then
			rm "$newPath${name}.prmtop"
		fi
		if [ -f "$newPath${name}.rst7" ]; then
			rm "$newPath${name}.rst7"
		fi
		mv $name.* $newPath
	fi
done
