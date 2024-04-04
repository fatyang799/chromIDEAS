#!/bin/bash

conda=$CONDA_PREFIX/bin
chromideas=~/Program/conda/chromIDEAS/1.version1/chromIDEAS/bins

ls ${chromideas}/* | egrep -v "soft_link.sh" | while read id
do
	base=$(basename $id)
	if [[ -f ${conda}/${base} ]]; then
		rm ${conda}/${base}
	fi
	ln -s ${id} ${conda}/
done

