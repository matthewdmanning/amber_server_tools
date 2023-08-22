#!/usr/bin/env scripts
# This script pulls common files from a remote Git repository to a local repo in the home (server) directory.

# Create git up alias. Apparently better than git pull. See https://stackoverflow.com/q/15316601/712605
git config --global alias.up '!git remote update -p; git merge --ff-only @{u}'
repo=amber_server_tools

(cd "${repo}" && git checkout master && git up)

if [ -f /home/mdmannin/git/amber_server_tools/amber_server_tools/ ]; then
	repo=/home/mdmannin/git/amber_server_tools/amber_server_tools
elif [ -f /home/mdmannin/git/amber_server_tools/ ]; then
	repo=/home/mdmannin/git/amber_server_tools
else
	printf "No git directory found. amber_server_tools not available!"
fi