#!/bin/bash

## This script will create a midthickness surface, map tensor and NODDI values to this surface, and compute stats for each ROI from Freesurfer parcellation

set -ex

#### Set cores ####
OMP_NUM_THREADS=8

#### make directory ###
mkdir -p metric raw ./cortexmap/cortexmap/label ./cortexmap/cortexmap/func

#### Variables ####
# parse inputs
echo "parsing inputs"
freesurfer=`jq -r '.freesurfer' config.json`
fmri=`jq -r '.fmri' config.json`
warp=`jq -r '.warp' config.json`
inv_warp=`jq -r '.inverse_warp' config.json`
fsurfparc=`jq -r '.fsurfparc' config.json`
echo "parsing inputs complete"

# set sigmas
echo "calculating sigma to use from dwi dimensions"
diffRes="`fslval ${dwi} pixdim1 | awk '{printf "%0.2f",$1}'`"
MappingFWHM="` echo "$diffRes * 2.5" | bc -l`"
MappingSigma=` echo "$MappingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
SmoothingFWHM=$diffRes
SmoothingSigma=` echo "$SmoothingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
echo "sigma set to ${MappingSigma}"

# set hemisphere labels
echo "set hemisphere labels"
HEMI="lh rh"
CARETHemi="L R"
echo "hemisphere labels set"

# if cortexmap already exists, copy
if [[ -f ${cortexmap}/surf/lh.midthickness.native.surf.gii ]]; then
	cp -R ${cortexmap}/label/* ./cortexmap/cortexmap/label/
	if [ ! -d ./cortexmap/cortexmap/surf ]; then
		mkdir ./cortexmap/cortexmap/surf
	fi
	cp -R ${cortexmap}/surf/* ./cortexmap/cortexmap/surf/
	if [ ! -z "$(ls -A ${cortexmap}/func/)" ]; then
		cp -R ${cortexmap}/func/* ./cortexmap/cortexmap/func/
	fi
	chmod -R +rw ./cortexmap
	cmap_exist=1
else
	cmap_exist=0
fi
