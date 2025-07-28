#!/bin/bash

# Program: bedGraph2bigWig get_bw
package_name="bedGraph2bigWig get_bw"
pkg="chromIDEAS"

# print help
if [[ -z $1 ]]; then
	echo "Usage: ${package_name}"
	echo -e "\t\$1: genomesizes file."
	echo -e "\t\$2: line ['${input} ${output}']."
	exit
fi

# get function from config:
# - check_status: check $? and if $? -ne 0, print $1 and execute command $2, then exit 100
# - file_check: if ! -f $1, print $1 and exit 100
# - dir_check: if ! -d $1, print $1 and create it
# - getFull_file: if ! -f $1, print $1 and exit 100; else print $1 full fileName
# - getFull_dir: if ! -d $1, create $1 and print full dirName, else print $1 full dirName
# - rm_empty: remove empty line in the file
if true; then
	bin_root=${CONDA_PREFIX}/share/${pkg}/bin
	source ${bin_root}/CHROMIDEAS_config.sh
fi

# get the arguments
if true; then
	genomesizes=$1
	line=$2
	input_bedgraph=$(echo ${line} | cut -d " " -f1)
	output_bw=$(echo ${line} | cut -d " " -f2)
fi

# bedGraph2bigWig
if true; then
	sort -k1,1 -k2,2n ${input_bedgraph} 1>${output_bw}.sort.bedgraph
	${bin_root}/bedGraphToBigWig ${output_bw}.sort.bedgraph ${genomesizes} ${output_bw} 1>/dev/null 2>/dev/null

	check_status "${package_name} 1 raise error, please check." "rm -rf ${output_bw}.sort.bedgraph ${output_bw}"

	rm ${output_bw}.sort.bedgraph
fi