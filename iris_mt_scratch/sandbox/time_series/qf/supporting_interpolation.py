#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 31 18:45:37 2017

@author: kkappler
"""


import os
#import matplotlib.pyplot as plt
import pdb
import numpy as np
import datetime
from scipy.interpolate import interp1d

home = os.path.expanduser("~/")


def interpolate_symmetric_function(x,y,**kwargs):
    """
    @kwarg kind: see doc for interp1d
    @TODO: add argument for about whcih axis we are symmetric
    default x=0
    @note: This function originally designed to use with fap-tables for 
    calibration calculations
    """
    log_scale = kwargs.get('logScale',True)
    kind = kwargs.get('kind','linear')
    if log_scale:
        temp_function = interp1d(np.log(x), np.log(y), kind=kind, 
                                 bounds_error=False, fill_value='extrapolate')
        interpolator = lambda f: np.exp(temp_function(np.log(np.abs(f))))
    else:
        temp_function = interp1d(x, y, kind=kind, 
                                 bounds_error=False, fill_value='extrapolate')
        interpolator = lambda f: temp_function(np.abs(f))
    return interpolator


def main():
    """
    """
    print("finito {}".format(datetime.datetime.now()))

if __name__ == "__main__":
    main()
