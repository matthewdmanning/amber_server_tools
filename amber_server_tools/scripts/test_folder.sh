#!/usr/bin/env scripts

source ~/PycharmProjects/nanorodbuilder/inFiles/folder_methods.sh

for folder in */; do
    path=${folder/'/'}
    system=$path
    prefix="ions"
    suffix=""
    get_continuous_traj "$path" "$system" "$prefix" "$suffix"
    echo "$cont_array"
done