#!/bin/bash

# ---------- SUMMARY ----------
# Compute connectivity correlation of tractogram
#
# Step 1 : Decompose connectivity
# Step 2 : Compute connectivity
# Step 3 : Compute correlation
# Step 4 : Compute binary correlation
# Step 5 : Compute confusion matrix


# e.g. ./DiSCo_compute_tractogram_connectivity.sh DiSCo1_DWI_shell_full.trk DiSCo1_ROIs.nii.gz DiSCo1_Connectivity_Matrix_Cross-Sectional_Area.txt outpath/

usage() {
  echo "$(basename $0) \
        [in_tractogram] \
        [in_rois] \
        [in_connectivity_truth] \
        [out_path]"; exit 1;
}

in_tractogram=""
in_rois=""
in_connectivity_truth=""
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

in_tractogram=$1
in_rois=$2
in_connectivity_truth=$3
out_path=$4

echo 

printf 'Input tractogram fname: %s\n' "${in_tractogram}"
printf 'Input ROIs fname: %s\n' "${in_rois}"
printf 'Input connectivity truth file fname: %s\n' "${in_connectivity_truth}"
printf 'Output path: %s\n' "${out_path}"

echo

base_name="$(basename ${in_tractogram})"
base_name="${base_name%%.*}"

truth_name="$(basename ${in_connectivity_truth})"
truth_name="${truth_name%%.*}"

echo "Output will be written to folder $out_path"
echo "Starting to compute on $in_tractogram..."


# Step 1 : Decompose connectivity
echo
echo "Step 1:"
echo "Decomposing connectivity..."
echo

scil_decompose_connectivity.py \
${in_tractogram} \
${in_rois} \
${out_path}/${base_name}_connectivity.h5 -f

# Step 2 : Compute connectivity
echo
echo "Step 2:"
echo "Computing connectivity..."
echo

scil_compute_connectivity.py \
${out_path}/${base_name}_connectivity.h5 \
${in_rois} \
--volume ${out_path}/${base_name}_connectivity.npy -f

# Step 3 : Compute correlation
echo
echo "Step 3:"
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

# Step 4 : Compute binary correlation
echo
echo "Step 4:"
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


# Step 5 : Compute confusion matrix
echo
echo "Step 5:"
echo "Computing confusion matrix..."
echo

./compute_confusion_matrix.py \
${out_path}/${base_name}_binary_connectivity.npy \
${out_path}/${truth_name}_binary.npy \
${out_path}/${base_name}_confusion_matrix.png



echo "Done. The final connectivity map is written in ${out_path} "

