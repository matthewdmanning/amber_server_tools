#!/usr/bin/env bash
# This script pulls common files from a remote Git repository to a local repo in the home (server) directory.

# Create git up alias. Apparently better than git pull. See https://stackoverflow.com/q/15316601/712605
git config --global alias.up '!git remote update -p; git merge --ff-only @{u}'
repo=amber_server_tools

(cd "${repo}" && git checkout master && git up)

