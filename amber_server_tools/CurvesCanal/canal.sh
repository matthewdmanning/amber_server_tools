#!/usr/bin/env bash

run_type=$1
nucleic_type=$2
na_sequence=$3

write_canal(){

na_type=$1

cda_prefix=curves_${na_type}
output_prefix=canal_out
canal_input=canal.inp
canal_dir=canal_${na_type}
#na_sequence=`sed '2q;d' ${cda_prefix}.cdi | xargs`
printf "Sequence is %s: \n" "${na_sequence}"


cat <<EOT > ${canal_input}
rm ${output_prefix}*
/home/mdmannin/curves+/canal <<!
 &inp
 lis=${output_prefix},
 histo=.t, series=.t,
&end
${cda_prefix} ${na_sequence}
!
EOT

chmod +x ${canal_input}

}

run_canal(){
    canal_dir=canal_${na_type}

    source ${canal_input}

    if [ ! -d ${canal_dir} ]; then
        mkdir ${canal_dir}
    fi

    mv ${output_prefix}_*.ser ${canal_dir}
    mv ${output_prefix}_*.his ${canal_dir}
}

path () {
	nucleic_type=$1
for path in */; do
    cd ${path}
    write_canal "$nucleic_type"
    run_canal "$nucleic_type"
    cd ..
done
}

if [[ $run_type == "path" ]]; then
	path "$nucleic_type"
else
	write_canal "$nucleic_type"
	run_canal
fi
