#!/bin/bash

# s3v2norm.sh
package_name="s3v2Norm s3v2norm"
pkg="chromIDEAS"

# default parameters
if true; then
	nthreads=4
	local_bg_bin=5
	rank_lim=0.001
	fdr_thresh=0.1
	upperlim=1000
	lowerlim=0
	p_method=z
fi

# read actual named input parameters
if true; then
	while getopts ":k:i:n:p:L:r:m:q:u:l:P:" opt
	do
		case $opt in
			k) mk="$OPTARG" ;;
			i) input_dir="$OPTARG" ;;
			n) uniq_mk_num="$OPTARG" ;;
			p) nthreads="$OPTARG" ;;
			L) local_bg_bin="$OPTARG" ;;
			r) rank_lim="$OPTARG" ;;
			m) metadata="$OPTARG" ;;
			q) fdr_thresh="$OPTARG" ;;
			u) upperlim="$OPTARG" ;;
			l) lowerlim="$OPTARG" ;;
			P) p_method="$OPTARG" ;;
			*) echo "Invalid option -$OPTARG"
			   exit 100 ;;
		esac
	done
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

# associate related files
if true; then
	common_pk_binary=${mk}_commonpkfdr01_z.cpk.txt
	common_bg_binary=${mk}_commonpkfdr01_z.cbg.txt

	if [[ ${uniq_mk_num} -eq 1 ]]; then
		allpk_binary=F
	else
		allpk_binary=${mk}_commonpkfdr01_z.allpk.txt
	fi
fi

# s3v2 normalization
if true; then
	# ${mk}.file_list.S3V2.txt: ${input_dir}/${cell}.${mk}.${id}.ip.idsort.bedgraph ${mk}.average_sig.bedgraph.S3.bedgraph ${cell}_${id} ${mk}
	cut -f1 ${mk}.file_list.txt | xargs basename -a | awk -F '.' -v OFS='\t' -v average=${mk}.average_sig.bedgraph.S3.bedgraph '{print $0, average, $1"_"$3, $2}' | sed "s#^#${input_dir}/#g" > ${mk}.file_list.S3V2.txt
	check_status "${package_name} 1 raise error, please check ${mk}." "rm -rf ${mk}.file_list.S3V2.txt"

	# output:
	# - ${cell}_${id}.${mk}.S3V2.bedgraph: normalized bedgraph file
	# - ${cell}_${id}.${mk}.S3V2.bedgraph.info.txt: normalization info
	cat ${mk}.file_list.S3V2.txt | xargs -n1 -i -P ${nthreads} \
		bash ${bin_root}/s3v2norm_sup.sh {} ${bin_root} ${fdr_thresh} ${local_bg_bin} ${rank_lim} ${upperlim} ${lowerlim} ${p_method} ${common_pk_binary} ${common_bg_binary} ${allpk_binary} ${uniq_mk_num}
	check_status "${package_name} 2 raise error, please check ${mk}." "rm -rf ${mk}.file_list.S3V2.txt *${mk}.S3V2.bedgraph *${mk}.S3V2.bedgraph.info.txt *${mk}.S3V2.bedgraph.low.value.txt"
fi

# get average of normalized dat
if true; then
	# ${mk}.getave_nbp.list.txt: ${cell}_${id}.${mk}.S3V2.bedgraph 	 ${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph
	cat ${metadata} | awk -F '\t' -v OFS='\t' -v used_mk=${mk} '{if ($2==used_mk) print $1"_"$3"."$2".S3V2.bedgraph",$1"."$2"."$3".ctrl.idsort.bedgraph.gz.norm.bedgraph"}' > ${mk}.getave_nbp.list.txt
	check_status "${package_name} 3 raise error, please check ${mk}." "rm -rf ${mk}.file_list.S3V2.txt *${mk}.S3V2.bedgraph* ${mk}.getave_nbp.list.txt"

	# output:
	# - ${mk}.average_sig.bedgraph.S3V2.ave.bedgraph
	Rscript ${bin_root}/get_average_sig.R ${mk}.getave_nbp.list.txt ${mk}.average_sig.bedgraph.S3V2.ave.bedgraph
	check_status "${package_name} 4 raise error, please check ${mk}." "rm -rf ${mk}.file_list.S3V2.txt *${mk}.S3V2.bedgraph* ${mk}.getave_nbp.list.txt ${mk}.average_sig.bedgraph.S3V2.ave.bedgraph ${mk}.average_sig.bedgraph.S3V2.ave.bedgraph.notused.files.txt"
fi

echo -e "\t3.S3V2 across samples\t${mk} done"