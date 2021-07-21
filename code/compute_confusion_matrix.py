#! /usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os

import numpy as np
import matplotlib.pyplot as plt

def _build_arg_parser():
    p = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description=__doc__)

    p.add_argument('in_binary_matrix')
    p.add_argument('in_ground_truth')
    p.add_argument('out_png')

    return p


def main():
    parser = _build_arg_parser()
    args = parser.parse_args()

    in_matrix = np.load(args.in_binary_matrix)
    gt = np.load(args.in_ground_truth)
    confusion_matrix = gt
    tp = 0
    fp = 0
    tn = 0
    fn = 0

    [i, j] = in_matrix.shape
    for x in range(0, i):
        for y in range(0, j):
            if in_matrix[x][y] == 1:
                if gt[x][y] == 1:
                    tp += 1
                    confusion_matrix[x][y] = 1
                if gt[x][y] == 0:
                    fp += 1
                    confusion_matrix[x][y] = 2
            if in_matrix[x][y] == 0:
                if gt[x][y] == 1:
                    fn += 1
                    confusion_matrix[x][y] = 4
                if gt[x][y] == 0:
                    tn += 1
                    confusion_matrix[x][y] = 3
    total = tp + fp + tn + fn

    print("True positives : " + str(100 * tp/total) + "%")
    print("False positives : " + str(100 * fp/total) + "%")
    print("True negatives : " + str(100 * tn/total) + "%")
    print("False negatives : " + str(100 * fn/total) + "%")

    fig, ax = plt.subplots()
    im = ax.imshow(confusion_matrix.T,
                   interpolation='nearest',
                   cmap='coolwarm')
    cbar = fig.colorbar(im, ticks=[1, 2, 3, 4])
    cbar.ax.set_yticklabels(['True Positives', 'False Positives',
                             'True Negatives', 'False Negatives'])

    plt.savefig(args.out_png, dpi=300, bbox_inches='tight')


if __name__ == "__main__":
    main()
