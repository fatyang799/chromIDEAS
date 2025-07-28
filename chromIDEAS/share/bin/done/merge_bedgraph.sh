#!/bin/bash

# Program: mergeBedgraph
package_name="mergeBedgraph merge_bedgraph"
pkg="chromIDEAS"

# get function from config:
# - check_status: check $? and if $? -ne 0, print $1 and execute command $2 (can be null), then exit 100
# - file_check: if ! -f $1, print $1 and exit 100
# - dir_check: if ! -d $1, print $1 and create it
# - getFull_file: print $1 full fileName
# - getFull_dir: if ! -d $1, create $1 and print full dirName, else print $1 full dirName
# - rm_empty: remove empty line in the file
# - data_type: check the input is one of gt0_Integer, le0_Integer, Character
if true; then
	bin_root=${CONDA_PREFIX}/share/${pkg}/bin
	source ${bin_root}/CHROMIDEAS_config.sh
fi

# get the arguments
if true; then
	group=$1
	file_list=$2
	average_method=$3
	cor_method=$4
	skipZeros=$5
	cutoff_cor=$6
	quiet=$7
fi

# get average value
if true; then
	files=$(awk -F "\t" -v group=${group} '{if($2 == group) {print $1}}' ${file_list})
	check_status "${package_name} 1 raise error, please check ${group}."

	paste ${files} > ${group}.merged.txt
	Rscript ${bin_root}/get_average_sig_merge_track.R ${group}.merged.txt ${group} ${average_method} ${cor_method} ${skipZeros} ${cutoff_cor} ${quiet} "${files}"
	check_status "${package_name} 2 raise error, please check ${group}." "rm -rf ${group}.merged.txt"

	rm -rf ${group}.merged.txt
fi