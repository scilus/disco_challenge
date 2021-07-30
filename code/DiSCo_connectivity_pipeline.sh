#!/bin/bash

# ---------- SUMMARY ----------
# Compute basic connectivity map on DiSCo
#
# Step 1 : Denoise DWI
# Step 2 : Extract shell used for WM and frf computing
# Step 3 : Compute FA map
# Step 4 : Compute tissue masks
# Step 5 : Compute frf
# Step 6 : Compute fodf
# Step 7 : either	- Compute local tracking (use 'local')
#			- Compute pft (use 'pft')
# Step 8 : Run commit
# Step 9 : Decompose connectivity
# Step 10 : Compute connectivity
# Step 11 : Compute correlation
# Step 12 : Compute binary correlation
# Step 13 : Compute confusion matrix

# Editable paramaters :
#	- FA threshold and dilation for white matter mask
#	- min_fa and fa for frf computation 
#	- sh_order for fodf computation
#	- tracking options (algo, step, npv...)	

# e.g. ./DiSCo_connectivity_pipeline.sh DiSCo_DWI_shell_full.nii.gz DiSCo_DWI_shell_full.bval DiSCo_DWI_shell_full.bvec DiSCo1_ROIs.nii.gz DiSCo1_Connectivity_Matrix_Cross-Sectional_Area.txt pft outpath/

usage() {
  msg="Usage: $(basename $0) [in_dwi] [in_bval] [in_bvec] [in_rois]"
  msg="$msg [in_connectivity_truth] [tracking_method] [out_path]"
  echo "$msg"; exit 1;
}

in_dwi=""
in_bval=""
in_bvec=""
in_rois=""
in_connectivity_truth=""
tracking_method=""
out_path="" 

# Parse input arguments
PARAMS=""

while (( "$#" )); do
  case "$1" in
    -h)
      usage
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

if [ "$#" -ne 7 ]
then
  echo "Error: Missing mandatory arguments"
  usage
fi

in_dwi=$1
in_bval=$2
in_bvec=$3
in_rois=$4
in_connectivity_truth=$5
tracking_method=$6
out_path=$7

dict_tracking_method=('local' 'pft')
method_exists=false

for method in "${dict_tracking_method[@]}"
do 
	if [ "$tracking_method" == "$method" ]; then
		method_exists=true
	fi
done

if ! $method_exists; then 
	echo "Tracking method is not valid. Use 'local' or 'pft'"
	exit 0
fi

echo 

printf 'Input DWI fname: %s\n' "${in_dwi}"
printf 'Input bval file fname: %s\n' "${in_bval}"
printf 'Input bvec file fname: %s\n' "${in_bvec}"
printf 'Input rois file fname: %s\n' "${in_rois}"
printf 'Input connectivity truth file fname: %s\n' "${in_connectivity_truth}"
printf 'Tracking method to use: %s\n' "${tracking_method}"
printf 'Output path: %s\n' "${out_path}"

echo

base_name="$(basename ${in_dwi})"
base_name="${base_name%%.*}"

truth_name="$(basename ${in_connectivity_truth})"
truth_name="${truth_name%%.*}"

echo "Output will be written to folder $out_path"
echo "Starting to compute on $in_dwi..."

# Step 1 : Denoise DWI
: '
echo
echo "Step 1:"
echo "Denoising DWI..."
echo

scil_run_nlmeans.py \
${in_dwi} \
${out_path}/${base_name}_denoised.nii.gz 1 \
--log ${out_path}/log.txt
'

# Step 2 : Extract shell used for WM and frf computation
echo
echo "Step 2:"
echo "Extracting shell used for WM and frf computation ..."
echo

scil_extract_dwi_shell.py \
${in_dwi} \
${in_bval} \
${in_bvec} \
0 1000 \
${out_path}/DWI_single_shell_b1000.nii.gz \
${out_path}/DWI_single_shell_b1000.bval \
${out_path}/DWI_single_shell_b1000.bvec -f

# Step 3 : Compute FA map
echo
echo "Step 3:"
echo "Computing $base_name FA map ..."
echo

scil_compute_dti_metrics.py \
${out_path}/DWI_single_shell_b1000.nii.gz \
${out_path}/DWI_single_shell_b1000.bval \
${out_path}/DWI_single_shell_b1000.bvec \
--not_all --fa ${out_path}/${base_name}_FA.nii.gz -f

# Step 4 : Compute tissue masks
echo
echo "Step 4:"
echo "Computing $base_name tissue masks..."
echo

wm_threshold=0.2
dilation=2
erosion=1

# Threshold FA for WM
scil_image_math.py lower_threshold \
${out_path}/${base_name}_FA.nii.gz \
${wm_threshold} \
${out_path}/${base_name}_FA_threshold.nii.gz -f

# Dilate FA for fuller WM
scil_image_math.py \
dilation \
${out_path}/${base_name}_FA_threshold.nii.gz \
${dilation} \
${out_path}/${base_name}_WM.nii.gz -f
 
# Erode FA for holes removal
scil_image_math.py \
erosion \
${out_path}/${base_name}_WM.nii.gz \
${erosion} \
${out_path}/${base_name}_WM.nii.gz -f

# Convert WM to mask
scil_image_math.py \
convert \
${out_path}/${base_name}_WM.nii.gz  \
${out_path}/${base_name}_WM.nii.gz \
-f --data_type uint8

in_mask=${out_path}/${base_name}_WM.nii.gz

# Binarize ROIs for GM
scil_image_math.py \
  lower_threshold \
  ${in_rois} \
  0.0 \
  ${out_path}/${base_name}_GM.nii.gz -f \

# Convert GM to mask
scil_image_math.py \
  convert \
  ${out_path}/${base_name}_GM.nii.gz \
  ${out_path}/${base_name}_GM.nii.gz \
  -f --data_type uint8

# Computing WM+GM mask for CSF
scil_image_math.py \
  union \
  ${out_path}/${base_name}_WM.nii.gz \
  ${out_path}/${base_name}_GM.nii.gz \
  ${out_path}/${base_name}_WMGM.nii.gz \
  --data_type uint8 -f

# Inverting WM+GM mask for CSF
scil_image_math.py \
  invert \
  ${out_path}/${base_name}_WMGM.nii.gz \
  ${out_path}/${base_name}_CSF.nii.gz -f \

# Visualize FA histogram with this WM mask 
scil_visualize_histogram.py \
${out_path}/${base_name}_FA.nii.gz \
${in_mask} \
8 ${out_path}/${base_name}_FA.png \
--title ${base_name} \
--x_label 'FA' -f


# Step 5 : Compute frf
echo
echo "Step 5:"
echo "Computing $base_name frf..."
echo

min_fa=0.4
fa=0.8

scil_compute_ssst_frf.py \
${out_path}/DWI_single_shell_b1000.nii.gz \
${out_path}/DWI_single_shell_b1000.bval \
${out_path}/DWI_single_shell_b1000.bvec \
${out_path}/${base_name}_frf.txt \
--mask_wm ${in_mask} \
--min_fa ${min_fa} --fa ${fa} -f

# Step 6 : Compute fodf
echo
echo "Step 6:"
echo "Computing $base_name fodf..."
echo

sh_order=8

scil_compute_ssst_fodf.py \
${in_dwi} \
${in_bval} \
${in_bvec} \
${out_path}/${base_name}_frf.txt \
${out_path}/${base_name}_fodf.nii.gz --sh_order ${sh_order} -f

if [ "$tracking_method" == "local" ]; then
	
	# Step 7 : Compute local tracking
	echo
	echo "Step 7:"
	echo "Computing local tracking ..."
	echo

	algo=prob
	step=0.5
	npv=1

	scil_compute_local_tracking.py \
	${out_path}/${base_name}_fodf.nii.gz \
	${in_mask} \
	${in_mask} \
	${out_path}/${base_name}_sft.trk \
	--algo ${algo} --step ${step} --npv ${npv} -f
fi

if [ "$tracking_method" == "pft" ]; then
	
	# Step 7 : Compute PFT
	echo
	echo "Step 7:"
	echo "Computing PFT ..."
	echo
	
	algo=prob
	
	scil_compute_maps_for_particle_filter_tracking.py \
	${out_path}/${base_name}_WM.nii.gz \
	${out_path}/${base_name}_GM.nii.gz \
	${out_path}/${base_name}_CSF.nii.gz \

	mv map_exclude.nii.gz ${out_path}/${base_name}_exclude.nii.gz
	mv map_include.nii.gz ${out_path}/${base_name}_include.nii.gz
	mv interface.nii.gz ${out_path}/${base_name}_interface.nii.gz

	scil_compute_pft.py \
	${out_path}/${base_name}_fodf.nii.gz \
	${out_path}/${base_name}_interface.nii.gz \
	${out_path}/${base_name}_include.nii.gz \
	${out_path}/${base_name}_exclude.nii.gz \
	${out_path}/${base_name}_sft.trk  \
	-f --algo ${algo}

fi

# Step 8 : Run Commit
echo
echo "Step 8:"
echo "Running Commit ..."
echo

commit_path=${out_path}/commit
mkdir -p ${commit_path}

scil_run_commit.py \
${out_path}/${base_name}_sft.trk \
${in_dwi} \
${in_bval} \
${in_bvec} \
${commit_path} \
--in_peaks ${out_path}/${base_name}_fodf.nii.gz \
--ball_stick -f 

mv ${commit_path}/commit_1/essential_tractogram.trk ${out_path}
mv ${out_path}/essential_tractogram.trk ${out_path}/${base_name}_sft_filtered.trk 

# Step 9 : Decompose connectivity
echo
echo "Step 9:"
echo "Decomposing connectivity..."
echo

scil_decompose_connectivity.py \
${out_path}/${base_name}_sft_filtered.trk \
${in_rois} \
${out_path}/${base_name}_connectivity.h5 -f

# Step 10 : Compute connectivity
echo
echo "Step 10:"
echo "Computing connectivity..."
echo

scil_compute_connectivity.py \
${out_path}/${base_name}_connectivity.h5 \
${in_rois} \
--volume ${out_path}/${base_name}_connectivity.npy -f

# Step 11 : Compute correlation
echo
echo "Step 11:"
echo "Computing correlation..."
echo

./convert_npy2txt.py \
${out_path}/${base_name}_connectivity.npy \
${out_path} 

./compute_correlation.py \
${in_connectivity_truth} \
${out_path}/${base_name}_connectivity.txt  

scil_visualize_connectivity.py \
${out_path}/${base_name}_connectivity.npy \
${out_path}/${base_name}_connectivity.png -f \

# Step 12 : Compute binary correlation
echo
echo "Step 12:"
echo "Computing binary correlation..."
echo

scil_connectivity_math.py lower_threshold  \
${out_path}/${base_name}_connectivity.npy \
0 \
${out_path}/${base_name}_binary_connectivity.npy \
--data_type int16 -f

scil_visualize_connectivity.py \
${out_path}/${base_name}_binary_connectivity.npy \
${out_path}/${base_name}_binary_connectivity.png -f \

./convert_npy2txt.py \
${out_path}/${base_name}_binary_connectivity.npy \
${out_path} 

# truth to binary
scil_connectivity_math.py lower_threshold \
${in_connectivity_truth} \
0 \
${out_path}/${truth_name}_binary.npy \
--data_type int16 -f

scil_visualize_connectivity.py \
${out_path}/${truth_name}_binary.npy \
${out_path}/${truth_name}_binary.png -f \

./convert_npy2txt.py \
${out_path}/${truth_name}_binary.npy  \
${out_path} 

# correlation
./compute_correlation.py \
${out_path}/${truth_name}_binary.txt \
${out_path}/${base_name}_binary_connectivity.txt  

scil_visualize_connectivity.py \
${out_path}/${base_name}_binary_connectivity.npy  \
${out_path}/${base_name}_binary_connectivity.png -f \


# Step 13 : Compute confusion matrix
echo
echo "Step 13:"
echo "Computing confusion matrix..."
echo

./compute_confusion_matrix.py \
${out_path}/${base_name}_binary_connectivity.npy \
${out_path}/${truth_name}_binary.npy \
${out_path}/${base_name}_confusion_matrix.png



echo "Done. The final connectivity map is written in ${out_path} "

