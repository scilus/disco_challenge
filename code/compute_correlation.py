#!/usr/bin/env python
# encoding: utf-8

import argparse
import numpy as np
import scipy.stats


def buildArgsParser():
    p = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
                                description="DiSCo Challenge connectivity evaluation script.")
    p.add_argument('GT', metavar='GT filename', action='store',
                   help='Input path to the ground truth connectivity matrix of the dataset.')
    p.add_argument('matrix', metavar='Matrix filename', action='store', type=str,
                   help='Input path to the estimated connectivity matrix of the dataset.')
    return p


def main():

    parser = buildArgsParser()
    args = parser.parse_args()
    GT = np.loadtxt(args.GT)
    matrix = np.loadtxt(args.matrix)
    
    if GT.shape != (16,16):
        parser.error("The ground truth connectivity matrix should have a shape 16x16. The input GT matrix has a shape %s" % str(GT.shape))
          
    if matrix.shape != (16,16):
        parser.error("The estimated connectivity matrix should have a shape 16x16. The input estimated matrix has a shape %s" % str(matrix.shape))
    
    #The Pearson correlation coefficient is computed on the lower triangle of the 16x16 array.
    mask = np.tril(np.ones(matrix.shape), -1) > 0
    r, pvalue = scipy.stats.pearsonr(GT[mask].flatten(), matrix[mask].flatten())
    
    print("The r coefficient is %f." % r)
        
                
if __name__ == "__main__":
    main()
    
    
