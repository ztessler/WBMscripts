#!/bin/bash

SRCtree="${1}"
DSTtree="${2}"

find -L "${SRCtree}" -name \*.gdbc |\
(while read SRCfile
 do
	DSTfile=$(echo "${SRCfile}" | sed "s:${SRCtree}:${DSTtree}:" | sed "s:\.gdbc:.nc:")
	[ -e "${DSTfile%/*}" ] || mkdir -p "${DSTfile%/*}" 
	rgis2netcdf "${SRCfile}" "${DSTfile}"
 done)
