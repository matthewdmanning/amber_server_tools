#!/usr/bin/env scripts

# Issue: Change args for non-NA sims.
run_type=$1
nucleic_type=$2
na_sequence=$3

write_canal(){

  na_type=$1
  cda_prefix=curves_${na_type}
  output_prefix=canal_out
  canal_input=canal.inp
  canal_outdir=canal_${na_type}
  canal_exe=$(find / -nowarn -executable -type f -name canal)
  #na_sequence=`sed '2q;d' ${cda_prefix}.cdi | xargs`
  #Issue Remove for non-NA sims.
  printf "Sequence is %s: \n" "${na_sequence}"

cat <<EOT > ${canal_input}
rm ${output_prefix}*
${canal_exe} <<!
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
    canal_outdir=canal_${na_type}

    source ${canal_input}

    if [ ! -d ${canal_outdir} ]; then
        mkdir ${canal_outdir}
    fi

    mv ${output_prefix}_*.ser ${canal_outdir}
    mv ${output_prefix}_*.his ${canal_outdir}
}

iter_path () {
	nucleic_type=$1
for sys_path in */; do
    cd ${sys_path}
    write_canal "$nucleic_type"
    run_canal "$nucleic_type"
    cd ..
done
}

if [[ $run_type == "path" ]]; then
	iter_path "$nucleic_type"
else
	write_canal "$nucleic_type"
	run_canal
fi
