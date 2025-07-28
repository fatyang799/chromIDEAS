#!/bin/bash

# Program: ideas.sh
package_name="chromIDEAS"
command="ideas.sh"

# define package related path
if true; then
	bin_root=${CONDA_PREFIX}/share/${package_name}/bin
	blacklist_root=${CONDA_PREFIX}/share/${package_name}/blacklist
	genomesize_root=${CONDA_PREFIX}/share/${package_name}/genomesize
	windows_root=${CONDA_PREFIX}/share/${package_name}/bin_windows
	gsl_root=${CONDA_PREFIX}/share/${package_name}/gsl
	manual_root=${CONDA_PREFIX}/share/${package_name}/manuals

	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${gsl_root}/lib
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
	source ${bin_root}/CHROMIDEAS_config.sh
fi

# get the arguments
if true; then
	metadata=$1
	out_dir=$2
	id=$3
	bed=$4
	otherpara=$5
	nthreads=$6
	impute=$7
	train=$8
	trainsz=$9
	C=${10}
	G=${11}
	minerr=${12}
	burnin=${13}
	mcmc=${14}
fi

time Rscript ${bin_root}/IDEAS_2018/bin/ideas.R \
	${metadata} \
	${out_dir} \
	${id} \
	${bed} \
	${otherpara} \
	${nthreads} \
	${impute} \
	${train} \
	${trainsz} \
	${C} \
	${G} \
	${minerr} \
	${burnin} \
	${mcmc} \
	F \
	${bin_root} 1>${out_dir}/std.log 2>${out_dir}/err.log

check_status "${package_name} raise error, please check." "rm -rf ${out_dir}/windowsNoBlack.withid.IDEASbins.txt ${out_dir}/Tracks"
