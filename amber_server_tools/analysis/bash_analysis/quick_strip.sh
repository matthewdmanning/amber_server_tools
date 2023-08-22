#!/usr/bin/env scripts


first_frame="1"
last_frame="last"
offset="100"
for path in */; do
    system=${path/'/'}
    cd $path
    traj_array=()
    for traj in *.nc; do
        if [ $traj == "*ions"* ] || [ $traj == "*strip*"] || [ $traj == "*skip*" ]; then
            continue
        fi
        md_suff=${traj#"${system}.md"}
        md_num=${md_suff%'.nc'}
        traj_array+=("${md_num}")
    done
    echo ${traj_array[@]}
    cd ..
done
trajin(){
    IFS=$'\n' sorted_md_array=($(sort <<<"${traj_array[*]}"))
    unset IFS
    echo "parm ${system}.prmtop" > traj.in
    echo "trajin ${system}.md1.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md2.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md3.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md4.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md5.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md6.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md7.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md8.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md9.nc 1 last 50" >> traj.in
    echo "trajin ${system}.md10.nc 1 last 50" >> traj.in
    echo "strip :WAT,Na+,Cl- outprefix strip" >> traj.in
    echo "trajout strip.${system}.md1-10.skip50.nc" >> traj.in
    echo "radgyr :225-384 tensor out ../skip50.rog.${system}.dat" >> traj.in
    echo "distance :225 :304 noimage out ../skip50.e2e.${system}.dat" >> traj.in
    echo "run" >> traj.in
    echo "quit" >> traj.in
    cpptraj -i traj.in
    cd ../
}
#done