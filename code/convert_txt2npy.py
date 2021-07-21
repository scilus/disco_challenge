#!/usr/bin/env python
# encoding: utf-8

import argparse
import os

import numpy as np


def _build_arg_parser():
    p = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description=__doc__)

    p.add_argument('in_txt')
    p.add_argument('out_path')

    return p


def main():
    parser = _build_arg_parser()
    args = parser.parse_args()

    in_txt_name = os.path.splitext(os.path.basename(args.in_txt))[0]

    txt = np.loadtxt(args.in_txt)
    np.save(os.path.join(args.out_path, in_txt_name + '.npy'), txt)


if __name__ == "__main__":
    main()
