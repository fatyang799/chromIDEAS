#!/bin/bash

# get_cpk_cbg_allpk_averagesig.sh
package_name="s3v2Norm get_cpk_cbg_allpk_averagesig"
pkg="chromIDEAS"

# get arguments
if true; then
	mk=$1
	metadata=$2
	input_dir=$3
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

# get ${cell}.${marker}.${id}.ip.idsort.bedgraph and ${cell}.${marker}.${id}.ctrl.idsort.bedgraph
if true; then
	cat ${metadata} | awk -F "\t" -v OFS="\t" -v used_mk=${mk} '{if ($2==used_mk) print $1"."$2"."$3".ip.idsort.bedgraph.gz"}' | sed "s#^#${input_dir}/#g" > ${mk}.file_list_tmp1
	cat ${metadata} | awk -F "\t" -v OFS="\t" -v used_mk=${mk} '{if ($2==used_mk) print $1"."$2"."$3".ctrl.idsort.bedgraph.gz"}' | sed "s#^#${input_dir}/#g" > ${mk}.file_list_tmp2
	paste ${mk}.file_list_tmp1 ${mk}.file_list_tmp2 > ${mk}.file_list.txt

	# remove redundent files
	rm -rf ${mk}.file_list_tmp1 ${mk}.file_list_tmp2
fi

### get cpk cbg: ${mk}_commonpkfdr01_z.cpk.txt ${mk}_commonpkfdr01_z.cbg.txt
if true; then
	# ${file_list_file} ${output_prefix} ${thresh} ${method} ${prob_pk} ${prob_bg}
	# output1: ${mk}_commonpkfdr01_z.cpk.txt, common pk file for all files with same marker
	# output2: ${mk}_commonpkfdr01_z.cbg.txt, common bg file for all files with same marker
	Rscript ${bin_root}/get_common_pk_p.R ${mk}.file_list.txt ${mk}_commonpkfdr01_z 0.1 z 1.0 1.0
	check_status "${package_name} 1 raise error, please check." "rm -rf ${mk}_commonpkfdr01_z* ${mk}.file_list.txt"
fi

### get allpk: ${mk}_commonpkfdr01_z.allpk.txt
if true; then
	cat ${mk}_commonpkfdr01_z.cbg.txt | awk '{if ($1 != 0) print 0; else print 1}' > ${mk}_commonpkfdr01_z.allpk.txt
	check_status "${package_name} 2 raise error, please check." "rm -rf ${mk}_commonpkfdr01_z* ${mk}.file_list.txt ${mk}_commonpkfdr01_z.allpk.txt"
fi

### get average signal: ${mk}.average_sig.bedgraph mean value for all ${cell}.${marker}.${id}.ip.idsort.bedgraph
if true; then
	Rscript ${bin_root}/get_average_sig.R ${mk}.file_list.txt ${mk}.average_sig.bedgraph
	check_status "${package_name} 3 raise error, please check." "rm -rf ${mk}_commonpkfdr01_z* ${mk}.file_list.txt ${mk}_commonpkfdr01_z.allpk.txt ${mk}.average_sig.bedgraph"
fi