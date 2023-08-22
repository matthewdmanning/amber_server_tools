#!/usr/bin/env scripts

buffer=10
salt=60
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
    local frcmod_dir="/home/mdmannin/Desktop/Nanoparticles/Ligands/Charged/frcmod/"
    local mol2_name=$1
    local leapin=$2
    echo "" > ${leapin}
	if [[ $dna == "True" ]]; then
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
	printf "loadamberparams AuNP.frcmod\n" >> ${leapin}
	for modpath in ${frcmod_dir}${frcmod}*.frcmod; do
		modfile=${modpath#$frcmod_dir}
		ligand=${modfile%'.frcmod'}
		if [[ "${nano_name}" == *"$ligand"* ]] && [[ -f ${modpath} ]]; then
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
	nano_name=${mol2_name%'.mol2'}
    local leapin="leap.in"
	echo "" > "$leapin"
    load_ffs "$mol2_name" "$leapin"
	echo ${leapin}
	#Load nanoparticle
	printf "nano = loadmol2 %s\n" "$mol2_name" >> ${leapin}
	printf "alignaxes nano\n" >> ${leapin}
	if [[ $bond_core == "True" ]]; then
	    printf "bondbyDistance nano.1 2.9\n" >> ${leapin}
	    printf "savemol2 nano %s 1\n" "$nano_name"_bond.mol2 >> ${leapin}
    fi
	#Neutralize and solvate NP
	#if [[ $solvate == "True" ]]; then
    printf "Solvating system...\n"
    printf "solvatebox nano TIP3PBOX %s\n" "$buffer" >> ${leapin}
    printf "addions nano Cl- 0\n" >> ${leapin}
    printf "addions nano Na+ 0\n" >> ${leapin}
    printf "addionsrand nano Na+ %s Cl- %s\n" "$salt" "$salt" >> ${leapin}
    #fi
    printf "saveamberparm nano %s.prmtop %s.rst7\n" "$nano_name" "$nano_name" >> ${leapin}
	printf "quit\n" >> ${leapin}
	if [[ -f leap.log ]]; then
    	rm leap.log
	fi
	if [[ $run == "True" ]]; then
    	tleap -f ${leapin} &> leap.log
	    #grep -v "maximum number of bonds" | grep -v "triangular" temp.log > leap.log
	    #more leap.log
	    #rm temp.log
	fi
	#grep [sS]tring leap.log
}

#printf "These are the available frcmod files."
#ls ${frcmod_dir}
#curdir=`pwd`
#leapin="${curdir}/leap.in"
sys_path="./"

# Loop through available files.
if [[ ${mol} == "True" ]]; then
    for mol2_name in *"${pattern}"*.mol2; do
        if [[ ! -f $mol2_name ]]; then
            echo $mol2_name
            continue
        fi
        nano_name=${mol2_name/'.mol2'}
        if [[ ! -d ${sys_path}${nano_name} ]]; then
            mkdir ${sys_path}${nano_name}
        fi
        mv ${mol2_name} ${sys_path}${nano_name}
        cd ${sys_path}${nano_name}
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