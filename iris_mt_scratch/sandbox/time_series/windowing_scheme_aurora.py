#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
The windowing scheme defines the chunking and chopping of the time series for the Short Time Fourier Transform.

It is often referred to as a "sliding window" or a "striding window".  It is basically a taper with a rule
to say how far to advance at each stride (or step).

All we really need is a window length and an overlap (or equivalently an advance).  We normally descibe
sliding windows in terms of overlap but we code in terms of "window_advance".


Note that choices of window length (L) and overlap (V)  are usually made with some knowledge of
time series sampling rate, duration, and the frequency band of interest.  We can create a module
that "suggests" L, V, based on these metadata to make the default processing configuration parameters.

Note: In general we will need one instance of this class per decimation level, but in the current
implementation we will probably leave it fixed.

This class is a key part of the "gateway" to frequency domain, so what frequency domain considerations do we want to
think about here.. certainly the window length and the sampling rate define the frequency resolution, and as such should
be considered in context of the "band averaging scheme"

Indeed the frequencies come from this class if it has a sampling rate ...
or should we push the frequency stuffs to a combination of TS plus WindowingScheme?  THe latter feels more appropriate.

"""

import numpy as np
import copy

from iris_mt_scratch.sandbox.time_series.apodization_window import ApodizationWindow

#from iris_mt_scratch.sandbox.time_series.window_helpers import sliding_window
from iris_mt_scratch.sandbox.time_series.window_helpers import available_number_of_windows_in_array
from iris_mt_scratch.sandbox.time_series.window_helpers import SLIDING_WINDOW_FUNCTIONS


#number_of_available_windows_in_array


class WindowingScheme(ApodizationWindow):
    """
    20210415: Casting everything in terms of number of samples or "points" as this is the nomenclature of the
    signal processing cadre.  We can provide functions to define things like overlap in terms of percent or
    Other colloquialisms in another module.

    Note that sampling_rate is actually a property of the data and not of the window ... still not sure if we want
    to make sampling_rate an attr here or if its better to put properties like window_duration() as a method
    of some composition of time series and windowing scheme.

    Seems like there is actually a Taper class that underlies this ... which has num_samples_taper, num
    """
    def __init__(self, **kwargs):
        super(WindowingScheme, self).__init__(**kwargs)
        self.num_samples_overlap = kwargs.get("num_samples_overlap", None)
        self.striding_function_label = kwargs.get("striding_function_label", "crude")

        # self.num_samples_data = kwargs.get("num_samples_data", None)
        #self.sampling_rate = kwargs.get('sampling_rate', None)
        #self.taper = ApodizationWindow(**kwargs)

        # if self.time_series_length > 0:
        #     self._compute_edge_indices()

    def clone(cls):
        return copy.deepcopy(cls)

    @property
    def num_samples_advance(self):
        """
        Attributes derived property that actually could be fundamental .. if we defined this we would wind up deriving
        the overlap.  Overlap is more conventional than advance in the literature however so we choose this as a prop.
        """
        return self.num_samples_window - self.num_samples_overlap


    def available_number_of_windows(self, num_samples_data):#, window_width, advance):
        """
        dont walk over the cliff.  Only take as many windows as available without wrapping
        you start with one window for free
        Parameters
        ----------
        num_samples_data

        Returns
        -------

        """
        available_number_of_windows = available_number_of_windows_in_array(num_samples_data,
                                                                           self.num_samples_window,
                                                                           self.num_samples_advance)
        return available_number_of_windows




#     @property
#     def window_edge_indices(self):
# #    def _compute_edge_indices(self):
#         """
#         2021: based on qf implementation ... trims so that all windows are not truncated ... the issue is that the
#         window as it advances will not normally land right at the end of the data ... so we lose a few points sometimes ...
#         TODO: raise a logger message when some data is ignored becuase of this
#         TODO: dictionarify this so that its self.edges["left"],self.edges["right"], de-qf it
#         TODO: Test an implementation of windowing that is based on numba and uses simple for looping
#         """
#         if self.num_samples_window > self.num_samples_data:
#             raise Exception("Data duration less than window duration")
#         self.left_indices = np.arange(0, self.num_samples_data, self.window_advance)
#         self.right_indices = self.left_indices + self.window_length
#         self.left_indices = self.left_indices[self.right_indices <= self.num_samples_data]
#         self.right_indices = self.right_indices[0:len(self.left_indices)]


    # @property
    # def num_windows(self):
    #     """
    #     Calculate number of windows
    #     """
    #     return len(self.left_edge_indices)


    @property
    def dt(self):
        """
        comes from data
        """
        return 1./self.sampling_rate

    @property
    def window_duration(self):
        """
        units are SI seconds assuming dt is SI seconds
        """
        return self.num_samples_window*self.dt



    def duration_advance(self):
        """
        """
        return self.num_samples_advance*self.dt


    @property
    def __str__(self):
        return "Window of {} samples with overlap {}".format(self.num_samples_window, self.num_samples_overlap)


    def apply_sliding_window(self, data):
        """
        
        Parameters
        ----------
        data

        Returns
        -------

        """
        sliding_window_function = SLIDING_WINDOW_FUNCTIONS[self.striding_function_label]
        reshaped_data = sliding_window_function(data, self.num_samples_window, self.num_samples_advance)
        return reshaped_data




def main():
    """
    Testing the windowing scheme
    """
    ws = WindowingScheme(num_samples_window=128, num_samples_overlap=32, num_samples_data=1000, taper='hamming')
    ws.sampling_rate = 50.0
    print(ws.window_duration)
    print("@ToDo Insert an integrated test showing common usage of sliding window\
    for 2D arrays, for example windowing for dnff")

    N = 10000
    windowing_scheme = WindowingScheme(num_samples_window=64, num_samples_overlap=50)
    print(windowing_scheme.num_samples_advance)
    print(windowing_scheme.available_number_of_windows(N))
    qq = np.random.random(N)
    ww = windowing_scheme.apply_sliding_window(qq)

    qq = np.arange(15)
    windowing_scheme = WindowingScheme(num_samples_window=3, num_samples_overlap=1)
    ww = windowing_scheme.apply_sliding_window(qq)
    print(ww)
    print("finito")

if __name__ == "__main__":
    main()

