#!/bin/bash

# get function from config:
# - check_status: check $? and if $? -ne 0, print $1 and execute command $2 (can be null), then exit 100
# - file_check: if ! -f $1, print $1 and exit 100
# - dir_check: if ! -d $1, print $1 and create it
# - getFull_file: print $1 full fileName
# - getFull_dir: if ! -d $1, create $1 and print full dirName, else print $1 full dirName
# - rm_empty: remove empty line in the file
# - data_type: check the input is one of gt0_Integer, 0, Character

# check program status
function check_status {
	status799=$?
	info799=$1
	command_after_wrong799=$2
	if [[ ${status799} -ne 0 ]]; then
		echo "${info799}"
		if [[ -n ${command_after_wrong799} ]]; then
			bash -c "${command_after_wrong799}"
		fi
		exit 100
	fi
}

# test whether the file exist
function file_check {
	input799=$1
	if [[ ! -f ${input799} ]]; then
		echo "Error: The ${input799} file is not exist."
		exit 100
	fi
}

# test whether the file exist
function dir_check {
	dir799=$1
	if [[ ! -d ${dir799} ]]; then
		echo "The ${dir799} directory is not exist. The program will create it."
		mkdir -p ${dir799}
	fi
}

# get full filename
function getFull_file {
	target799=$1

	dir799=$(dirname ${target799})
	dir799=$(getFull_dir ${dir799})
	filename799=$(basename ${target799})
	target799=${dir799}/${filename799}

	echo "${target799}"
}

# get full directory
function getFull_dir {
	now799=$PWD
	target799=$1
	
	mkdir -p ${target799}
	cd ${target799}
	target799=$PWD
	cd ${now799}

	echo "${target799}"
}

# remove empty line in the file
function rm_empty {
	input799=$1
	egrep -v "^\s*$" ${input799} > ${input799}.799799799.tmp
	mv ${input799}.799799799.tmp ${input799}
}

# check data type of input
function data_type {
	input799=$1

	if [[ ${input799} =~ ^[0-9]+$ ]]; then
		if [[ ${input799} -gt 0 ]]; then
			echo "gt0_Integer"
		else
			echo "0"
		fi
	else
		echo "Character"
	fi
}