#!/usr/bin/env scripts

buffer=10
salt=0
water=tip3p
dna="False"
rna="False"
mol="False"
folder="False"
run="False"
while [[ $1 = -* ]]; do
    arg=$1; shift           # shift the found arg away.
    case $arg in
        -p)
            pattern=$1
            shift
            ;;
        -buff)
            buffer=$1
            shift
            ;;
        -s)
            salt=$1
            shift
            ;;
        -dna)
            dna="True"
            ;;
        -rna)
            rna="True"
            ;;
        -wat)
            water=$1
            shift
            ;;
        -solvate)
            solvate="True"
            ;;
        -f)
            folder="True"
            ;;
        -mol)
            mol="True"
            ;;
        -run)
            run="True"
            ;;
        -bond)
            bond_core="True"
        esac
done

load_ffs(){
    local mol2_name=$1
    local leapin=$2
    shift 2
    [[ -f ${leapin} ]] && rm ${leapin}
    echo "" > ${leapin}
    while [[ $1 = -* ]]; do
      arg=$1; shift
      case $arg in
        -frcmod)
          frcmod_namelist=()
          local mod=$1
          [[ $mod != -* ]] && frcmod_namelist=()
          while [[ $mod != -* ]]; do
            frcmod_namelist+=$mod
            shift
          done
          ;;
        -modfile)
          local mod_file=$1
          ;;
      esac
    done
  # Issue: Move this to NP project specific file.
  while IFS="" read -r p || [ -n "$p" ]; do
    printf 'loadamberparams %s\n' "$p" >> ${leapin}
  done < $mod_file
	for frcmod_name in ${frcmod_namelist[@]}; do
  	printf "loadamberparams ${frcmod_name}.frcmod\n" >> ${leapin}
    # Issue: Remove for non-NA simulations. Allow explicit loading of FFs.
  while IFS="" read -r p || [ -n "$p" ]; do
    printf 'loadamberparams %s\n' "$p" >> ${leapin}
  done < $mod_file	if [[ $dna == "True" ]]; then
    	printf "source leaprc.DNA.OL15\n" >> ${leapin}
	elif [[ $rna == "True" ]]; then
	    printf "source leaprc.RNA.OL3\n" >> ${leapin}
	else
	    printf "source leaprc.protein.ff14SB\n" >> ${leapin}
	fi
	#if [[ "$solvate" == "True" ]]; then
    printf "source leaprc.water.%s\n" "$water" >> ${leapin}
	#fi
	printf "source leaprc.gaff2\n" >> ${leapin}
  # Issue: Move this to NP project specific file.
	for modpath in ${frcmod_dir}${frcmod}*.frcmod; do
		modfile=${modpath#$frcmod_dir}
		ligand=${modfile%'.frcmod'}
		if [[ "${sys_name}" == *"$ligand"* ]] && [[ -f ${modpath} ]]; then
			printf "loadamberparams %s\n" "$modpath" >> ${leapin}
		fi
	done
}

write_leap_file(){
    mol2_name=$1
	if [[ ! -f ${mol2_name} ]]; then
	    printf "mol2 file %s does not exist.\n" "$mol2_name"
        return
	fi
	sys_name=${mol2_name%'.mol2'}
    local leapin="leap.in"
	echo "" > "$leapin"
    load_ffs "$mol2_name" "$leapin"
	echo ${leapin}
	#Load nanoparticle
	printf "topo = loadmol2 %s\n" "$mol2_name" >> ${leapin}
	printf "alignaxes topo\n" >> ${leapin}
	# Issue: Move this to NP project specific file.
	if [[ $bond_core == "True" ]]; then
	    printf "bondbyDistance topo.1 2.9\n" >> ${leapin}
	    printf "savemol2 topo %s 1\n" "$sys_name"_bond.mol2 >> ${leapin}
    fi
  # Issue: Doesn't allow for other water models!
	#Neutralize and solvate NP
	#if [[ $solvate == "True" ]]; then
    printf "Solvating system...\n"
    printf "solvatebox topo TIP3PBOX %s\n" "$buffer" >> ${leapin}
    printf "addions topo Cl- 0\n" >> ${leapin}
    printf "addions topo Na+ 0\n" >> ${leapin}
    printf "addionsrand topo Na+ %s Cl- %s\n" "$salt" "$salt" >> ${leapin}
    #fi
    printf "saveamberparm topo %s.prmtop %s.rst7\n" "$sys_name" "$sys_name" >> ${leapin}
	printf "quit\n" >> ${leapin}
	if [[ -f leap.log ]]; then
    	rm leap.log
	fi
	if [[ $run == "True" ]]; then
    	tleap -f ${leapin} &> leap.log
	fi
}

sys_path="./"

# Loop through available files.
if [[ ${mol} == "True" ]]; then
    for mol2_name in *"${pattern}"*.mol2; do
        if [[ ! -f $mol2_name ]]; then
            echo $mol2_name
            continue
        fi
        sys_name=${mol2_name/'.mol2'}
        if [[ ! -d ${sys_path}${sys_name} ]]; then
            mkdir ${sys_path}${sys_name}
        fi
        mv ${mol2_name} ${sys_path}${sys_name}
        cd ${sys_path}${sys_name}
        write_leap_file "$mol2_name"
        cd ..
    done
elif [[ ${folder} == "True" ]]; then
    pwd
    for path in */; do
        #if [[ ! -z "$pattern" ]] && [[ ${path} != *"$pattern"* ]]; then
        #    echo "Pattern ${pattern} does not match ${path}."
        #    continue
        #fi
        echo $path
        cd ${path}
        pwd
        for mol2_name in *.mol2; do
            if [[ -f ${mol2_name} ]]; then
                write_leap_file "$mol2_name"
            fi
        done
        cd ..
    done
fi