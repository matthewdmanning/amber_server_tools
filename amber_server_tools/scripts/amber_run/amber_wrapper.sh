#!/usr/bin/env scripts
echo $repo
echo "$@"
if [[ -f ${repo}/bash/run_amber.sh ]]; then
    nohup source ${repo}/bash/run_amber.sh "$@" &> job.log &
fi