#!/bin/scripts
# Script for Curves bash_analysis
#  1. Create .trj file from .x files using cpptraj
#  2. Use Curves+ and Canal to generate data
#  3. Use Python to process data and make plots

source /usr/local/apps/env/hoomd.sh 2.1.2

for d in */ ; do
   echo "Calling directory $d"
   prefix=`echo $d |sed 's/_.*//'`
   echo "The prefix is $prefix"
   cd $d
   topFile=`echo $prefix*.prmtop`
   echo "parm $topFile" > cpptraj.in

   for x in md*.x ; do
      echo "trajin $x 1 6000 2" >> cpptraj.in
   done

   echo "strip !:1-200 outprefix RNA" >> cpptraj.in
   echo "autoimage" >> cpptraj.in
   echo "trajout md_allRNA.trj" >> cpptraj.in
   echo "run" >> cpptraj.in

   cpptraj <cpptraj.in

   rm r+RNA_all*.*

   echo "/home/janash/storage/toStorage/sdc1/jessica/Curves+/Cur+<<!" > curves_all.inp
   echo "&inp" >> curves_all.inp
   echo " ftop=RNA.$topFile, file=md_allRNA.trj" >> curves_all.inp
   echo " lis=r+RNA_all,ions=.t,axfrm=.t," >> curves_all.inp
   echo " lib=/home/janash/storage/toStorage/sdc1/jessica/Curves+/standard," >> curves_all.inp
   echo "&end" >> curves_all.inp
   echo "2 1 -1 0 0" >> curves_all.inp
   echo "1:100" >> curves_all.inp
   echo "200:101" >> curves_all.inp
   echo "!" >> curves_all.inp

   chmod +x curves_all.inp
   curves_all.inp

  rm canal_all.* canal_all*.*
  echo "/home/janash/storage/toStorage/sdc1/jessica/Curves+/canal<<!" > canal_all.inp
  echo "&inp" >> canal_all.inp
  echo " lis=canal_all," >> canal_all.inp
  echo " lev1=0,lev2=0," >> canal_all.inp
  echo " series=.t, histo=.t," >> canal_all.inp
  echo "&end" >> canal_all.inp
  echo "r+RNA_all AUCAAUAUCCACCUGCAGAUUCUACCAAAAGUGUAUUUGGAAACUGCUCCAUCAAAAGGCAUGUUCAGCUGAAUUCAGCUGAACAUGCCUUUUGAUGGAG" >> canal_all.inp
echo "!" >> canal_all.inp

  chmod +x canal_all.inp
  ./canal_all.inp

  mkdir canal_all
  mv canal_*.ser canal_all/
  mv canal_*.his canal_all/

  cp ../pythonPlots.py canal_all

  cd canal_all/

  python pythonPlots.py

  cd ../../

done
