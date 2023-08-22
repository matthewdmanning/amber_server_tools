#!/bin/bashry
# Script for moving files

gpuPath='/home/mdmannin/mnt2/Ligands/'
print $gpuPath
ligPath='/home/mdmannin/Desktop/Nanoparticles/RoughNanorods/ParmFiles/'
cd $ligPath
pwd
for f in *_vac.prmtop ; do
  echo "Calling file $f"
  name=${f%'.prmtop'}
  newPath=$gpuPath$name/
  mkdir $newPath
  mv $name.* $newPath

done
