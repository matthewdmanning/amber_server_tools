#!/usr/bin/env bash
echo $repo
echo "$@"
if [[ -f ${repo}/bash/run_amber.sh ]]; then
    nohup source ${repo}/bash/run_amber.sh "$@" &> job.log &
fi