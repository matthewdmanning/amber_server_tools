#!/bin/bash
# Script for protect topology/restart/trajector files from deletion or overwriting

masterdir="/mdmannin/home/mnt1/"
cd $masterdir

shopt -s globstar #turns on recursive globbing


for f in */* ; do
	if [[ $f == *'prmtop' ]]; then
		chmod a-w $f
		echo $f
		rst=${f/prmtop/rst7}
		echo $rst
		chmod a-w $rst
	fi
	if [ $f == *'nc' ] || [ $f == *.'rst']; then
		chmod a-w $f
	fi
done

#for f in *.* ; do
#  echo "Calling file $f"
#  name=${f%'.prmtop'}
#  newPath=$gpuPath$name/
#  mkdir $newPath
#  mv $name.* $newPath
#
#done
