DiSCo Challenge
---------------

######################
DiSCo_connectivity_pipeline.sh 
######################

Basic pipeline for DiSCo challenge. Includes direct connectivity comparaison with Ground Truth.


######################
DiSCo_compute_tractogram_connectivity.sh 
######################

Steps 9 to 13 of DiSCo_connectivity_pipeline. Allows direct connectivity comparaison of a tractogram with Ground Truth.

######################
compute_correlation.py 
######################

To test your estimated connectivity matrix run the following command:

python compute_correlation.py Training_DiSCo1/DiSCo1_Connectivity_Matrix_Cross-Sectional_Area.txt example_random_connectivity_matrix.txt

You should obtain the following output:
The r coefficient is 0.187509.


*Change 'example_random_connectivity_matrix.txt' with your estimated connectivity matrix. The text file should contain an array with 16 rows and 16 columns, each associated to the corresponding ROI. The Pearson correlation coefficient is computed on the lower triangle of the 16x16 array.

##################
convert_npy2txt.py
##################

To convert the numpy array output of scil_compute_connectivity.py in txt format, in order to use compute_correlation.py. 

Output file is written with the name of input file, and will be save in the path provided.

e.g. ./convert_npy2txt.py map_connectivity.npy outpath/


##################
convert_txt2npy.py
##################

To convert the DiSCo1_Connectivity_Matrix_Cross-Sectional_Area.txt in npy format, in order to use scil_visualise_connectivity.py and compare with our connectity maps.

Output file is written with the name of input file, and will be save in the path provided.

e.g. ./convert_npy2txt.py map_connectivity.npy outpath/


##################
compute_confusion_matrix.py
##################

To compute the confusion matrix 

e.g. ./compute_confusion_matrix.py binary_connectivity.npy turth_binary_connectivity.npy 

You should obtain the following output:

True positives : 19.53125%
False positives : 43.75%
True negatives : 36.71875%
False negatives : 0.0%





