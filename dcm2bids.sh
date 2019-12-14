#!/bin/bash

#---------------- HELP ----------------#
help() {
echo "
	1st argument = top level directory

This script will convert your structural DICOM images into NIFTI and organize them into the BIDS. It requires you to specify the folder where your 'DICOM' folder is, and that every directory within that folder is named by the ID of the corresponding subject (e.g. 01, 02, 03, [...]). It further expects a standard DICOM outcome, like:
> DICOM
	>> 01
		>>> 1800 (or whatever)
					>>> DICOM
						    >>>>> * .dcm files*

It should also be mentioned that it uses the dcm2niix pipeline, so you should have that installed.

### This script is based on: https://github.com/franklin-feingold/BIDS-Example-NKI-RS-Multiband-Imaging ###
"
}

# # # # # # # # # # # # Variables # # # # # # # # # # # # # 
toplvl=$1
dcmdir=${toplvl}/DICOM
niidir=${toplvl}/NIFTI

# -----------------------------------------------------------------------------------------------#

## checking if the input is valid
if [[ -d $1 ]]; then
    echo "$1 is a directory"
else
    echo "$1 is not valid"
    help
    exit 1
fi


## create NIFTI dir
cd $toplvl
mkdir NIFTI

## Labeling

for direcs in $(ls ${dcmdir}); do
	id=`echo $direcs`;
	echo "[INFO] ID $id created at `date`" >> $toplvl/dcm2bids_log.txt
	

	## Create NIFTI directories
	
	mkdir -p ${niidir}/sub-$id/anat;
	echo "[INFO] Directory sub-$id/anat created in $niidir at `date` " >> $toplvl/dcm2bids_log.txt

	## Convert atatomical Dicoms 2 NIFTI and put them in the corresponding folders
	
	
	dcm2niix -o ${niidir}/sub-$id/anat -f sub-$id_%f_%p ${dcmdir}/*${id}*/**/DICOM; 
	echo "[INFO] DICOM images of sub-$id (stored in $dcmdir/*${id}*/**/DICOM) converted into NIFTI and stored in $niidir/sub-$id/anat, at `date` " >> $toplvl/dcm2bids_log.txt
	
	#change direc
	cd ${niidir}/sub-$id

	# Rename stuctural NIFTI files
    anatfiles=$(ls -1 ${niidir}/**/**/*FSPGR_BRAVO* | wc -l)
    for ((i=1;i<=${anatfiles};i++)); do
    	Anat=$(ls ${niidir}/**/**/*FSPGR_BRAVO*) 
    	tempanat=$(ls -1 $Anat | sed '1q;d') 
    	tempanatext="${tempanat##*.}"
    	tempanatfile="${tempanat%.*}"
			mv ${tempanatfile}.${tempanatext} sub-${id}_ses-1_T1w.nii.${tempanatext}
			echo -e "[INFO] ${tempanat} changed to sub-${id}_T1w.${tempanatext}" >> $toplvl/dcm2bids_log.txt
    done
	mv ${niidir}/sub-$id/*_T1w* ${niidir}/sub-$id/anat
	echo "[INFO] ${niidir}/sub-$id/*_T1w* moved to ${niidir}/sub-$id/anat" >> $toplvl/dcm2bids_log.txt


done
