#!/bin/bash


#---------------- HELP ----------------#
help() {
echo "
	1st argument = folder where NIFTI files are
	2nd argument = study prefix (optional)
	3rd argument = Subjects' ID first delimiter (optional)
	4th argument = Sebjects' ID second delimiter (optional)

The 3rd and 4th argument must be included only if the ID delimiters are other than _ . For example, if the file names are something like: \"sub_01_bob.nii.gz\" , these arguments need not be included. If the file names go something like: \"sub-01.bob.nii.gz\" , the third argument should be: \"-\" and the fourth: \".\"

Examples:

> ./N4_script.sh /misc/path/to/niftidirectory MR

> ./N4_script.sh /misc/path/to/niftidirectory MR - .
 
-Eliseo
"
}

# # # # # # # # # # # # Variables # # # # # # # # # # # # # 
topdir=$1
prefix=$2

# -----------------------------------------------------------------------------------------------#

## checking if the input is valid
if [[ -d $1 ]]; then
    echo "$1 is a directory"
else
    echo "$1 is not valid"
    help
    exit 1
fi

if [ -z "$2" ]; then
    prefix=MR
    echo "STANDARD STUDY PREFIX ASSIGNED: $prefix"
else
    prefix=$2	
    echo "STUDY PREFIX IS: $prefix"  
fi

## create required dirs
mkdir ${topdir}/final
mkdir ${topdir}/process ${topdir}/process/mnc ${topdir}/process/nlm ${topdir}/process/niis ${topdir}/process/n4

step_mnc=${topdir}/process/mnc
step_nlm=${topdir}/process/nlm 
step_niis=${topdir}/process/niis
step_n4=${topdir}/process/n4


## define file names
cd $topdir
for nii in *.nii*; do

	if [ -z "$3" ]; then
	id=`echo $nii | cut -d "_" -f 2 | cut -d "_" -f 1`

	else
	id=`echo $nii | cut -d "$3" -f 2 | cut -d "$4" -f 1`
	fi

echo "[INFO] ID $id WAS CREATED AND ADDED TO PRE-PROCESSING"
input_file=$nii
N4_file=$step_n4/${id}_n4.nii.gz
minc_file=$step_mnc/${id}_m1.mnc
nlm_file=$step_nlm/${id}_nlm.mnc
nii_file=$step_niis/${id}_n2.nii.gz
# mnc_file=${topdir}/mncfiles/$3_${id}_t1.mnc

## process
echo "[INFO]... N4 bias field correction en $step_n4: $N4_file" >> $topdir/log_n4.txt
N4BiasFieldCorrection -d 3 -i $input_file -o $N4_file

echo "[INFO]... Creando un archivo minc en $step_mnc: $minc_file" >> $topdir/log_n4.txt
ConvertImage 3 $N4_file $minc_file

echo "[INFO]... Aplicando la limpieza de ruido con non-local means en $step_nlm: $nlm_file" >> $topdir/log_n4.txt
mincnlm $minc_file $nlm_file

echo "[FINAL INFO]... Corrigiendo archivo MINC en $topdir/final: $2_${id}_t1.mnc" >> $topdir/log_n4.txt

ConvertImage 3 $nlm_file $nii_file
nii2mnc $nii_file $topdir/final/$2_${id}_t1.mnc

done
