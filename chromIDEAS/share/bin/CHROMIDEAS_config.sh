#!/bin/bash

# get function from config:
# - check_status: check $? and if $? -ne 0, print $1 and execute command $2, then exit 100
# - file_check: if ! -f $1, print $1 and exit 100
# - dir_check: if ! -d $1, print $1 and create it
# - getFull_file: print $1 full fileName
# - getFull_dir: if ! -d $1, create $1 and print full dirName, else print $1 full dirName
# - rm_empty: remove empty line in the file

# check program status
function check_status {
	status=$?
	info=$1
	command_after_wrong=$2
	if [[ ${status} -ne 0 ]]; then
		echo "${info}"
		bash -c "${command_after_wrong}"
		exit 100
	fi
}

# test whether the file exist
function file_check {
	input=$1
	if [[ ! -f ${input} ]]; then
		echo "The ${input} file is not exist."
		exit 100
	fi
}

# test whether the file exist
function dir_check {
	dir=$1
	if [[ ! -d ${dir} ]]; then
		echo "The ${dir} directory is not exist. The program will create it."
		mkdir -p ${dir}
	fi
}

# get full filename
function getFull_file {
	now=$PWD
	target=$1

	dir=$(dirname ${target})
	dir=$(getFull_dir ${dir})
	filename=$(basename ${target})
	target=${dir}/${filename}
	cd ${now}

	echo "${target}"
}

# get full directory
function getFull_dir {
	now=$PWD
	target=$1
	
	mkdir -p ${target}
	cd ${target}
	target=$PWD
	cd ${now}

	echo "${target}"
}

# remove empty line in the file
function rm_empty {
	input=$1
	egrep -v "^\s*$" ${input} > ${input}.tmp
	mv ${input}.tmp ${input}
}