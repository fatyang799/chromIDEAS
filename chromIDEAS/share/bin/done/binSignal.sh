#!/bin/bash

# binSignal.sh
package_name="bigWig2bedGraph binSignal"

# get arugments
if true; then
	line=$1
	bin_root=$2
	windows_dir=$3
	zip=$4

	# $line format: input<tab>output
	input=$(echo ${line} | cut -d " " -f1)
	output=$(echo ${line} | cut -d " " -f2)

	window_noid=${windows_dir}/windowsNoBlack.noid.bed
	window_withid=${windows_dir}/windowsNoBlack.withid.bed
fi

# get function from config:
# - check_status: check $? and if $? -ne 0, print $1 and execute command $2 (can be null), then exit 100
# - file_check: if ! -f $1, print $1 and exit 100
# - dir_check: if ! -d $1, print $1 and create it
# - getFull_file: print $1 full fileName
# - getFull_dir: if ! -d $1, create $1 and print full dirName, else print $1 full dirName
# - rm_empty: remove empty line in the file
if true; then
	source ${bin_root}/CHROMIDEAS_config.sh
fi

# bw2bedgraph
if true; then
	${bin_root}/bigWigAverageOverBed ${input} ${window_withid} ${output}.tmp 1>/dev/null 2>&1
	check_status "Error: ${package_name} 1 raise error, please check." "rm -rf ${output}.tmp"

	sort -k1,1n ${output}.tmp | cut -f 5 | paste ${window_noid} - > ${output}
	check_status "Error: ${package_name} 2 raise error, please check." "rm -rf ${output}.tmp ${output}"

	if [[ ${zip} == "T" ]]; then
		gzip -f ${output}
	fi
fi

rm -rf ${output}.tmp
echo "${input} has been converted to bedgraph format succussfully."