#!/bin/bash

package_name="chromIDEAS"

# set -e: exit if run fail
# set -o pipefail: the return value of a pipeline (|) is the value of the last (rightmost) command to exit with a non-zero status, or zero if all commands in the pipeline  exit  successfully.
set -e
set -o pipefail

# cp additional scripts file to ${CONDA_PREFIX}/share
# bin:			${CONDA_PREFIX}/share/${package_name}/bin
# blacklist:	${CONDA_PREFIX}/share/${package_name}/blacklist
# genomesize:	${CONDA_PREFIX}/share/${package_name}/genomesize
# gsl:			${CONDA_PREFIX}/share/${package_name}/gsl
# manuals:		${CONDA_PREFIX}/share/${package_name}/manuals
mkdir -p ${CONDA_PREFIX}/share/${package_name}
mkdir -p ${CONDA_PREFIX}/bin/

cp -rf ${SRC_DIR}/share/bin ${CONDA_PREFIX}/share/${package_name}
cp -rf ${SRC_DIR}/share/blacklist ${CONDA_PREFIX}/share/${package_name}
cp -rf ${SRC_DIR}/share/genomesize ${CONDA_PREFIX}/share/${package_name}
cp -rf ${SRC_DIR}/share/manuals ${CONDA_PREFIX}/share/${package_name}
cp -rf ${SRC_DIR}/share/gsl ${CONDA_PREFIX}/share/${package_name}
tar xf ${CONDA_PREFIX}/share/${package_name}/gsl/gsl_221.tar.gz -C ${CONDA_PREFIX}/share/${package_name}/gsl/
rm -rf ${CONDA_PREFIX}/share/${package_name}/gsl/gsl_221.tar.gz

cp -rf ${SRC_DIR}/bins/* ${CONDA_PREFIX}/bin/
