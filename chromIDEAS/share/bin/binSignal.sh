#!/bin/bash

# binSignal.sh
package_name="bigWig2bedGraph binSignal"

# get arugments
if true; then
	line=$1
	out_dir=$2
	bin_root=$3
	windows_dir=$4
	zip=$5

	# $line format: cell<tab>mark<tab>id<tab>file.bw<tab>input.bw
	cell=$(echo ${line} | cut -d " " -f1)
	marker=$(echo ${line} | cut -d " " -f2)
	id=$(echo ${line} | cut -d " " -f3)
	file_bw=$(echo ${line} | cut -d " " -f4)
	input_bw=$(echo ${line} | cut -d " " -f5)

	window_noid=${windows_dir}/windowsNoBlack.noid.bed
	window_withid=${windows_dir}/windowsNoBlack.withid.bed
fi

# get function from config:
# - check_status: check $? and if $? -ne 0, print $1 and execute command $2, then exit 100
# - file_check: if ! -f $1, print $1 and exit 100
# - dir_check: if ! -d $1, print $1 and create it
# - getFull_file: if ! -f $1, print $1 and exit 100; else print $1 full fileName
# - getFull_dir: if ! -d $1, create $1 and print full dirName, else print $1 full dirName
# - rm_empty: remove empty line in the file
if true; then
	source ${bin_root}/CHROMIDEAS_config.sh
fi

out_dir=$(getFull_dir ${out_dir})

# bw2bedgraph for exp
if true; then
	${bin_root}/bigWigAverageOverBed ${file_bw} ${window_withid} ${out_dir}/${cell}.${marker}.${id}.tmp 1>/dev/null 2>&1
	check_status "${package_name} 1 raise error, please check." "rm -rf ${out_dir}/${cell}.${marker}.${id}.tmp"

	sort -k1,1n ${out_dir}/${cell}.${marker}.${id}.tmp | cut -f 5 | paste ${window_noid} - > ${out_dir}/${cell}.${marker}.${id}.ip.idsort.bedgraph
	check_status "${package_name} 2 raise error, please check." "rm -rf ${out_dir}/${cell}.${marker}.${id}.tmp ${out_dir}/${cell}.${marker}.${id}.ip.idsort.bedgraph"

	if [[ ${zip} == "T" ]]; then
		gzip -f ${out_dir}/${cell}.${marker}.${id}.ip.idsort.bedgraph
	fi
fi

# bw2bedgraph for ct
if true; then
	if [[ -f ${input_bw} ]]; then
		${bin_root}/bigWigAverageOverBed ${input_bw} ${window_withid} ${out_dir}/${cell}.${marker}.${id}.control.tmp 1>/dev/null 2>&1
		check_status "${package_name} 3 raise error, please check." "rm -rf ${out_dir}/${cell}.${marker}.${id}.*tmp ${out_dir}/${cell}.${marker}.${id}.ip.idsort.bedgraph"

		sort -k1,1n ${out_dir}/${cell}.${marker}.${id}.control.tmp | cut -f 5 | paste ${window_noid} - > ${out_dir}/${cell}.${marker}.${id}.ctrl.idsort.bedgraph
		check_status "${package_name} 4 raise error, please check." "rm -rf ${out_dir}/${cell}.${marker}.${id}.*tmp ${out_dir}/${cell}.${marker}.${id}.*.idsort.bedgraph"
	else
		cp ${out_dir}/tmpControl.bed ${out_dir}/${cell}.${marker}.${id}.ctrl.idsort.bedgraph
		check_status "${package_name} 5 raise error, please check." "rm -rf ${out_dir}/${cell}.${marker}.${id}.*tmp ${out_dir}/${cell}.${marker}.${id}.*.idsort.bedgraph"
	fi

	if [[ ${zip} == "T" ]]; then
		gzip -f ${out_dir}/${cell}.${marker}.${id}.ctrl.idsort.bedgraph
	fi
fi

rm -rf ${out_dir}/${cell}.${marker}.${id}.tmp ${out_dir}/${cell}.${marker}.${id}.control.tmp
echo "${cell}.${marker}.${id} has been converted to bedgraph format succussfully."