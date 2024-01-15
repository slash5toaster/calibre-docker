#!/usr/bin/env bash

[[ $DEBUG ]] && set -x
ROOT_FOLDER=/usr/local/calibre-web

mkdir -vp $ROOT_FOLDER/config/
cps -r -p $ROOT_FOLDER/config/

