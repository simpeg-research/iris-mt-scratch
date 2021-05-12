#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
The windowing scheme defines the chunking and chopping of the time series for the Short Time Fourier Transform.

It is often referred to as a "sliding window" or a "striding window".  It is basically a taper with a rule
to say how far to advance at each stride (or step).

To generate an array of windows we only need window length and an overlap (or equivalently an advance).  We
normally descibe sliding windows in terms of overlap but we code in terms of "window_advance".

Note that choices of window length (L) and overlap (V)  are usually made with some knowledge of
time series sampling rate, duration, and the frequency band of interest.  We can create a module
that "suggests" L, V, based on these metadata to make the default processing configuration parameters.

Note: In general we will need one instance of this class per decimation level, but in the current
implementation we will probably leave the windowing scheme the same for each decimation level.

This class is a key part of the "gateway" to frequency domain, so what frequency domain considerations do we want to
think about here.. certainly the window length and the sampling rate define the frequency resolution, and as such should
be considered in context of the "band averaging scheme"

Indeed the frequencies come from this class if it has a sampling rate.  While sampling rate is a property
 of the data, and not the windowing scheme per se, it is good for this class to be aware of the sampling
 rate.  ... or should we push the frequency stuffs to a combination of TS plus WindowingScheme?
 The latter feels more appropriate.

<20210510>
When 2D arrays are generated how should we index them?
[[ 0  1  2]
 [ 2  3  4]
 [ 4  5  6]
 [ 6  7  8]
 [ 8  9 10]
 [10 11 12]
 [12 13 14]]
 In this example the rows are indexing the individual windows ... and so they should be associated
 with the time of each window.  We will need to set a standard for this.  Obvious options are
 center_time of window and time_of_first sample. I prefer time_of_first sample.  This can always be
 transformed to center time or any other standard later.  We can call this the "window time axis"
 The columns are indexing "steps of delta-t".  The actual times are different for every row, so it would be best
 to use something like [0, dt, 2*dt] for that axis to keep it general.  We can call this the
 "within-window sample time axis"

 Try making it an xarray.
 </20210510>

There is an open trade here about wheter to embed the data length as an ivar or a variable we pass.
i.e. whether the same windowing scheme is independent of the data length or not.

"""

import copy
import numpy as np
import xarray as xr

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
        self._left_hand_window_edge_indices = None
        # self.num_samples_data = kwargs.get("num_samples_data", None)
        #self.sampling_rate = kwargs.get('sampling_rate', None)
        #self.taper = ApodizationWindow(**kwargs)

        # if self.time_series_length > 0:
        #     self._compute_edge_indices()

    def clone(cls):
        return copy.deepcopy(cls)

    @property
    def __str__(self):
        return "Window of {} samples with overlap {}".format(self.num_samples_window, self.num_samples_overlap)

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

    def apply_sliding_window(self, data, time_vector=None, dt=None,
                             return_xarry=False):
        """

        Parameters
        ----------
        data
        time_vector: standin for the time coordinate of xarray.
        dt: stand in for sampling interval

        Returns
        -------

        """
        sliding_window_function = SLIDING_WINDOW_FUNCTIONS[self.striding_function_label]
        reshaped_data = sliding_window_function(data, self.num_samples_window, self.num_samples_advance)

        #<FACTOR TO ANOTHER METHOD>
        if return_xarry:
            print("test casting to xarray here")

            #<Get window_time_axis coordinate>
            if time_vector is None:
                time_vector = np.arange(len(data))
            multiple_window_time_axis = self.downsample_time_axis(time_vector)
            #</Get window_time_axis coordinate>

            #<Get within-window_time_axis coordinate>
            if dt is None:
                print("Warning dt not defined, using dt=1")
                dt = 1.0
            within_window_time_axis = dt*np.arange(self.num_samples_window)
            #<Get within-window_time_axis coordinate>

            #<Cast to xarray>
            xrd = xr.DataArray(reshaped_data, dims=["time", "within-window time"],
                               coords={"within-window time": within_window_time_axis,
                                       "time": multiple_window_time_axis})
            #</Cast to xarray>
            return xrd
        #</FACTOR TO ANOTHER METHOD>
        else:
            return reshaped_data

    def xarray_sliding_window(self, data, time_vector=None, dt=None):
        pass

    def compute_window_edge_indices(self, num_samples_data):
        """This has been useful in the past but maybe not needed here"""
        number_of_windows = self.available_number_of_windows(num_samples_data)
        self._left_hand_window_edge_indices= np.arange(number_of_windows)*self.num_samples_advance
        return

    def left_hand_window_edge_indices(self, num_samples_data):
        if self._left_hand_window_edge_indices is None:
            self.compute_window_edge_indices(num_samples_data)
        return self._left_hand_window_edge_indices

    def downsample_time_axis(self, time_axis):
        lhwe = self.left_hand_window_edge_indices(len(time_axis))
        multiple_window_time_axis = time_axis[lhwe]
        return multiple_window_time_axis

    def apply_taper(self):
        pass


#<PROPERTIES THAT NEED SAMPLING RATE>
#these may be moved elsewhere later
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


#</PROPERTIES THAT NEED SAMPLING RATE>






def apply_taper_to_windowed_array(taper, windowed_array):
    """
    This method will eventually become a class method but leaving the pure linear algebra call as a
    separate routine for easier future dev.  Will make assumptions here about the shape and dimensions
    of windowed array that can be handled in class method.

    Parameters
    ----------
    taper
    windowed_array

    Returns
    -------

    """
    print("hello")
    tapered_array = windowed_array.data * taper #this seems to do spare diag mult
    #time trial it against a few other methods
    return tapered_array



def test_can_instantiate_scheme():
    ws = WindowingScheme(num_samples_window=128, num_samples_overlap=32, num_samples_data=1000, taper='hamming')
    ws.sampling_rate = 50.0
    print(ws.window_duration)
    print("assert some condtion here")
    return

def test_can_apply_sliding_window():
    N = 10000
    qq = np.random.random(N)
    windowing_scheme = WindowingScheme(num_samples_window=64, num_samples_overlap=50)
    print(windowing_scheme.num_samples_advance)
    print(windowing_scheme.available_number_of_windows(N))
    ww = windowing_scheme.apply_sliding_window(qq)
    return ww

def test_can_apply_sliding_window_and_return_xarray():
    qq = np.arange(15)
    windowing_scheme = WindowingScheme(num_samples_window=3, num_samples_overlap=1)
    ww = windowing_scheme.apply_sliding_window(qq, return_xarry=True)
    print(ww)
    return ww

def test_can_apply_taper():
    import matplotlib.pyplot as plt
    N = 10000
    qq = np.random.random(N)
    windowing_scheme = WindowingScheme(num_samples_window=64, num_samples_overlap=50,
                                       family="hamming")
    print(windowing_scheme.num_samples_advance)
    print(windowing_scheme.available_number_of_windows(N))
    windowed_data = windowing_scheme.apply_sliding_window(qq)
    print("get taper")
    tapered_windowed_data = apply_taper_to_windowed_array(windowing_scheme.taper, windowed_data)
    plt.plot(windowed_data[0],'r');plt.plot(tapered_windowed_data[0],'g')
    plt.show()
    print("ok")
    return


def main():
    """
    Testing the windowing scheme
    """
    test_can_instantiate_scheme()
    ww = test_can_apply_sliding_window()
    ww = test_can_apply_sliding_window_and_return_xarray()
    test_can_apply_taper()
    print("@ToDo Insert an integrated test showing common usage of sliding window\
    for 2D arrays, for example windowing for dnff")
    print("finito")

if __name__ == "__main__":
    main()

