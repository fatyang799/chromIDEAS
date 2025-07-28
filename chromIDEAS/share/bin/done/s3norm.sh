#!/bin/bash

# s3norm.sh
package_name="s3v2Norm s3norm"
pkg="chromIDEAS"

# get arugments
if true; then
	mk=$1
fi

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

python3 ${bin_root}/s3norm.py -r ${bin_root}/prior/H3K27ac.average_sig.sample200k.seed2019.bedgraph -t ${mk}.average_sig.bedgraph -o ${mk}.average_sig.bedgraph.S3.bedgraph -c T 1>${mk}.average_sig.bedgraph.log 2>&1

check_status "${package_name} raise error, please check." "rm -rf ${mk}.average_sig.bedgraph.S3.bedgraph ${mk}.average_sig.bedgraph.S3.bedgraph.info.txt"