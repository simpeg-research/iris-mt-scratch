"""
This class is concerned with bookeeping of a set of MultiVariateTimeSeries objects.

This is intended primarily to mirror the functionality of Egbert's TTS.m but also to
work more generally.  The simplest indexing scheme is to use a dictionary.

There are two primary functions of this class
1. Binding related data together in a convenient container
2. The ability to apply operations (e.g. decimate, FFT, etc) onto the whole collection of MVTS with a single command




"""
from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries




class TimeSeriesCollection(object):
    """

    """
    def __init__(self, **kwargs):
        self.mvts_dict = kwargs.get('mvts_dict', None)

    def some_method(self):
        pass