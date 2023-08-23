#!/usr/bin/env scripts
# This script pulls common files from a remote Git repository to a local repo in the home (server) directory.

# Create git up alias. Apparently better than git pull. See https://stackoverflow.com/q/15316601/712605
git config --global alias.up '!git remote update -p; git merge --ff-only @{u}'
repo_name=amber_server_tools

(cd "${repo_name}" && git checkout master && git up)

if [ -f ${HOME}/git/${repo_name}/${repo_name}/ ]; then
	repo=${HOME}/git/${repo_name}/${repo_name}
elif [ -f ${HOME}/git/${repo_name}/ ]; then
	repo=${HOME}/git/${repo_name}
else
	printf "No git directory found. ${repo_name} not available!"
fi