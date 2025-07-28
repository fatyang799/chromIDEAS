#!/bin/bash

# s3v2norm_sup.sh

# get arguments
if true; then
	# line = ${input_dir}/${cell}.${mk}.${id}.ip.idsort.bedgraph ${mk}.average_sig.bedgraph.S3.bedgraph ${cell}_${id} ${mk}
	line=$1
	script_dir=$2
	fdr_thresh=$3
	local_bg_bin=$4
	rank_lim=$5
	upperlim=$6
	lowerlim=$7
	p_method=$8
	common_pk_binary=$9
	common_bg_binary=${10}
	allpk_binary=${11}
	uniq_mk_num=${12}

	# parse the line
	single_raw_sig=$(echo $line | cut -d " " -f1)
	average_sig=$(echo $line | cut -d " " -f2)
	cell_id=$(echo $line | cut -d " " -f3)
	mk=$(echo $line | cut -d " " -f4)

	# define related files
	# the output
	outfile=${cell_id}.${mk}.S3V2.bedgraph
	# log file
	log=${outfile}.log
	# script
	script=${script_dir}/s3v2norm_IDEAS.R
fi

# command
source ${script_dir}/CHROMIDEAS_config.sh

Rscript ${script} ${single_raw_sig} ${average_sig} ${outfile} ${fdr_thresh} ${local_bg_bin} F ${rank_lim} ${upperlim} ${lowerlim} ${p_method} ${common_pk_binary} ${common_bg_binary} ${allpk_binary} ${uniq_mk_num} 1>>${log} 2>>${log}
check_status "s3v2Norm s3v2norm s3v2norm_sup.sh raise error, please check ${mk}."