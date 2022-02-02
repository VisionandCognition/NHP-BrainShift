#!/bin/bash
rootfld=$HOME'/Documents/MRI_ANALYSIS/NHP-BrainShift'
datafld=$HOME'/Dropbox/CURRENT_PROJECTS/NHP_MRI/Projects/BrainShift'

#SUB='danny'
SUB='eddy'

cd $datafld/input/sub-$SUB

# normalize individual scans
mkdir -p $datafld/normalized/sub-$SUB
for f in *.nii.gz; do
	echo $f
	mri_nu_correct.mni --i $f --o $datafld/normalized/sub-$SUB/nu_$f --distance 24
done 

# get the motion corrected average
mkdir -p $datafld/aligned/sub-$SUB
cd $datafld/normalized/sub-$SUB
mri_motion_correct2 -o $datafld/aligned/sub-$SUB/avg_sub-$SUB.nii.gz -wild *.nii.gz
rm $datafld/aligned/sub-$SUB/*.xfm

# align template to get mask
flirt -in $datafld/mask/sub-$SUB/sub-${SUB}_ref_anat_res-0.5x0.5x0.5.nii.gz \
	-ref $datafld/aligned/sub-$SUB/avg_sub-$SUB.nii.gz \
	-omat $datafld/mask/sub-$SUB/mask2avg.mat

# register mask
flirt -in $datafld/mask/sub-$SUB/sub-${SUB}_ref_anat_mask_res-0.5x0.5x0.5.nii.gz \
	-ref $datafld/aligned/sub-$SUB/avg_sub-$SUB.nii.gz \
	-out $datafld/aligned/sub-$SUB/bm_sub-$SUB.nii.gz \
	-applyxfm -init $datafld/mask/sub-$SUB/mask2avg.mat


# align each volume rigidly to the average
cd $datafld/normalized/sub-$SUB
for f in *.nii.gz; do
	echo $f
	flirt -refweight $datafld/aligned/sub-$SUB/bm_sub-$SUB.nii.gz -dof 6 \
		-in $f -ref $datafld/aligned/sub-$SUB/avg_sub-$SUB.nii.gz -out $datafld/aligned/sub-$SUB/al_$f 
done

# generate a 4d volume
mkdir -p $datafld/4d
fslmerge -t $datafld/4d/4d_al_sub-$SUB.nii.gz $datafld/aligned/sub-$SUB/al_*.nii.gz
