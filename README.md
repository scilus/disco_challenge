# DiSCo Challenge repo for the SCIL team

This is the main repository of the processing pipeline for the SCIL's submission to the [MICCAI CDMRI 2021 DiSCo Challenge](http://hardi.epfl.ch/static/events/2021_challenge/). 

## Data

All of the relevant data is stored on braindata (`braindata/datasets/DiSCo`). Three datasets are available:
- DiSCo1 is the training data, for which we have the ground-truth connectivity matrix.
- DiSCo3 is the validation data, for which we also have the ground-truth connectivity matrix.
- DiSCo2 is the test data, for which we do not have the ground-truth connectivity matrix.

## Getting started

To run the base version of the pipeline on the training data, you can run

```bash
$ cd code
$ bash -x DiSCo_connectivity_pipeline.sh ~/braindata/databases/DiSCo/sub-DiSCo1/sub-DiSCo1_DWI_RicianNoise-snr30.nii.gz ~/braindata/databases/DiSCo/sub-DiSCo1/sub-DiSCo1_DWI_RicianNoise-snr30.bval ~/braindata/databases/DiSCo/sub-DiSCo1/sub-DiSCo1_DWI_RicianNoise-snr30.bvec ~/braindata/databases/DiSCo/sub-DiSCo1/sub-DiSCo1_ROIs.nii.gz ~/braindata/databases/DiSCo/sub-DiSCo1/sub-DiSCo1_Connectivity_Matrix_Cross-Sectional_Area.txt pft training
```

which should net you an r coefficient of around ~0.80.

## Participating
To participate, simply fork this repo and start hacking ! You can add, remove or modify steps of the main pipeline as you wish.

## Other teams' members
Of course, because this repository is public, we cannot prevent anyone from looking. However, if you are part of another team, we would encourage you to not take inspiration from this repo.
