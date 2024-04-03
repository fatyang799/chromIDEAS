#!/bin/bash

# Program: bedGraph2bigWig get_bw
package_name="mergeBedgraph merge_bedgraph_with_sameMK"
pkg="chromIDEAS"

# print help
if [[ -z $1 ]]; then
	echo "Usage: ${package_name}"
	echo -e "\t\$1: group."
	echo -e "\t\$2: file which record input_bedgraph and its group"
	echo -e "\t\$3: the out_dir directory"
	echo -e "\t\$4: zip or not"
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
	group=$1
	file=$2
	out_dir=$3
	zip=$4
fi

if [[ ${zip} == "T" ]]; then
	awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file} | xargs -n1 -i gunzip {}
	files=$(awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file} | sed "s/\.gz$//g")
else
	files=$(awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file})
fi
if [[ $? -ne 0 ]]; then
	if [[ ${zip} == "T" ]]; then
		awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file} | sed "s/\.gz$//g" | xargs -n1 -P5 -i gzip {}
	fi
	echo "${package_name} 1 raise error, please check ${group}."
	exit 100
fi

paste ${files} | gzip > ${out_dir}/${group}.S3V2.bedgraph.NBP.gz
Rscript ${bin_root}/get_mean_signal_track.R ${out_dir}/${group}.S3V2.bedgraph.NBP.gz ${out_dir}/${group}.S3V2.bedgraph.NBP.txt

if [[ $? -ne 0 ]]; then
	rm -rf ${out_dir}/${group}.S3V2.bedgraph.NBP.gz ${out_dir}/${group}.S3V2.bedgraph.NBP.txt
	if [[ ${zip} == "T" ]]; then
		awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file} | sed "s/\.gz$//g" | xargs -n1 -P5 -i gzip {}
	fi
	echo "${package_name} 2 raise error, please check ${group}."
	exit 100
else
	rm -rf ${out_dir}/${group}.S3V2.bedgraph.NBP.gz
	if [[ ${zip} == "T" ]]; then
		awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file} | sed "s/\.gz$//g" | xargs -n1 -P5 -i gzip {}
	fi
	echo "${group} group: all data have been merged successfully."
fi