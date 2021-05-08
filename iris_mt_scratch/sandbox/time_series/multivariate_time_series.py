"""
ToDo: make a version of this that bases on xarray

Time Handling should support:
-simple integer indexing, arbitrary clock-zero and pandas Timestamps
-https://towardsdatascience.com/timestamp-vs-timedelta-vs-time-period-afad0a48a7d1
-pd.TimeStamp based on numpy.datetime64
-pd.TimeDeltaIndex: Immutable ndarray of timedelta64 data, represented internally as int64, and which can be boxed to timedelta objects.
-pd.DateTimeIndex: Represented internally as int64, and which can be boxed to Timestamp objects that are subclasses of datetime and carry metadata.


OK, so when an MVTS operates, we can do one of two ways: channel by channel, or "en-masse".  It is highly
likely that xarray will provide the capability to do "en-masse" functions, for window, taper, fft,
BUT in the interests of training_wheels_to_xarray, I suggest we first implement in a way that runs
channel-by-channel.

However, I think, lets try to use xarray here, ever for the channel-by-channel approach.

That way a univariate time series is just an MVTS with only a single channel.

Then a method MVTS.merge_channels() should be able to bring everything back.


"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import time
import xarray as xr

class WindowedMultiVariateTimeSeries(MultiVariateTimeSeries):
    """
    This class is like a measurand whose parent is a time series ... full multivariate implementation looks
    like it may
    """
    def __init__(self):
        self.attribute = None

class MultiVariateTimeSeries(object):
    """
    Generic class for handling time series.

    To Decide: init method requires data or not?  This class is intended to be used for
    the case of time series that have data.  However, there maybe cases where we want to generate the data
    in the init method of the class extending this base.

    ?Do we want to populate with an xarray outside this method?

    How to store the xarray?  The xarray is like a property of the MVTS, ... or  ...
    should we use an xarray as the base class itself?  I think we should store
    it as an attr; otherwise we will have trouble with class methods...
    although one could write a collection of methods that operate
    on an xarray ... 

    """

    def __init__(self, **kwargs):
        kwargs = self.validate_kwargs(**kwargs)
        self.sampling_rate = kwargs.get('sampling_rate', None)
        self.xarray = kwargs.get('xarray', None) #NEW
        self.metadata = kwargs.get('metadata', None) #NEW key it with the xarray channel labels

        self.data = kwargs.get('data', None)  #OLD
        self.dims = kwargs.get('dims', []) #OLD
        self.t0 = kwargs.get('t0', None) #OLD: replace with property returns earliest timestamp in xarray
        self._duration = kwargs.get('duration', None) #OLD replace with @property len(data)*dt
        self.metadata = kwargs.get('metadata', None)
        self._time_vector = None #OLD: replace with reference to time-axis of xarray

        if self.data is not None:
            pass

    @property
    def channel_labels(self):
        return list(self.xarray.channel.values)
    

    @property
    def sampling_rate(self):
        return self.xarray.meta_dict['sampling_rate']

    def channel(self, channel_label):
        """
        This currently returns the channel data ... do we want to return an xarray with the embedded metadata?

        Parameters
        ----------
        channel_label

        Returns
        -------

        """
        return self.xarray.loc[:,channel_label]


    def apply_windowing_scheme(self, windowing_scheme):
        """:
        Returns an xarray ... hmm, or maybe another instance of self ... or better yet a "time domain instance"
        of STFT ... that would be best ... where STFT is typically the container for frequency domain data

        For now we will do this channel by channel ...
        """
        for channel_id in self.channel_labels:
            channel_data = self.channel(channel_id)
            windowed_data = 

    def apply_windowing_channel(self, channel_label):
        pass

    # def cast_data_to_xarray(self):
    #     qxr = xr.DataArray(qq[frequency_columns].values,
    #                        dims=('k', 'frequency'),
    #                        coords={'k': qq.k.values, 'frequency': frequency_bands})

    def validate_kwargs(self, **kwargs):
        """
        check for duplicate definintions, e.g. (sps & dt), (data & duration),

        Parameters
        ----------
        kwargs

        Returns
        -------

        """
        return kwargs
    #     #<sps, dt handler>
    #     sps = kwargs.get('sps', None)
    #     dt = kwargs.get('dt', None)
    #     if (sps is not None) and (dt is not None):
    #         print("Duplicate definition of sampling rate: this shouldn't happen")
    #         raise Exception
    #
    #     if sps is None:
    #         if dt is None:
    #             print("you didn't define sampling rate ... ")
    #             print("not sure yet if I should raise an exception or set sps=1.0")
    #             raise Exception
    #         if dt is not None:
    #             kwargs['sps'] = 1./dt
    #             kwargs.__delitem__('dt')
    #     #</sps, dt handler>
    #
    #     #<data, duration handler>
    #     print("WRITE A data / duration ingest handler")
    #     """
    #     This is actually a little bit tricky. There are cases where we would want to
    #     define a time series by giving it a duration, and then let the data generate according
    #     to some process.  But there are other cases where we want to pass data and let the
    #     duration be defined in terms of the sampling rate and the data itself.
    #     In the first case duration becomes a defined property.
    #     In the second case it is a derived property
    #     We could use _duration for the definition, and if _duration is None return
    #     """
    #     data = kwargs.get('data', None)
    #     duration = kwargs.get('duration', None)
    #     if (data is None) and (duration is None):
    #         print("Time series has no data or duration, Probably not a good situation.")
    #         print("Not sure if we should raise exception ... or let user construct it... ")
    #         raise Exception
    #     if (data is not None) and (duration is not None):
    #         print("Duplicate definition of sampling rate: this shouldn't happen")
    #         raise Exception
    #     #</data, duration handler>
    #     return kwargs


    # def validate(self):
    #     """
    #     check a few conditions:
    #     If sampling_rate and dt were provided, give a warning, and check that they
    #     are consistent, i.e. 1/sps=dt, else throw exception
    #     If dt is provided, store as sampling rate,
    #     If dt is zero throw an exception
    #     Returns
    #     -------
    #
    #     """
    #     pass

    @property
    def dt(self):
        return 1. / self.sampling_rate

    @property
    def n_samples(self):
        if self.data is not None:
            return len(self.data)
        else:
            return int(self.duration * self.sampling_rate)

    @property
    def time_vector(self):
        if self._time_vector is None:
            time_vector = self.dt * np.arange(self.n_samples)
            self._time_vector = time_vector
        return self._time_vector

    @property
    def duration(self):
        if self._duration is None:
            return self.dt * self.n_samples
        else:
            return self._duration

#<FREQUENCY DOMAIN>
    @property
    def df(self):
        N = self.n_samples
        dt = self.dt
        df = 1. / (N * dt)
        return df

    def frequency_axis(self, one_sided=True):
        frequencies = np.fft.fftfreq(self.n_samples, self.dt)
        #frequencies = df*np.arange(self.n_samples)
        #if one_sided:
        #    pass
        #if not one_sided:#two sided
        #    print("have to handle odd and even case")
        return frequencies

    def fft(self):
        fourier_transform = np.fft.fft(self.data)
        return fourier_transform
#</FREQUENCY DOMAIN>

    def _update(self):
        """
        Run a sequence of consistency checks
        Returns
        -------

        """
        pass


def test_generate_time_axis(t0, n_samples, sampling_rate):
    """
    Two obvious ways to generate an axis of timestanps here.
    One method is slow and more precise, the other is fast but drops some nanoseconds due to integer roundoff error.

    Parameters
    ----------
    t0
    n_samples
    sampling_rate

    Returns
    -------

    """
    t0 = np.datetime64(t0)
    dt = 1. / sampling_rate

    # <SLOW>
    #the issue here is that the nanoseconds granularity forces a roundoff error,
    #in the example of say 3Hz, we are 333333333ns between samples, which drops 1ns
    #per second.  To get around that we can use this slow method
    tt = time.time()
    time_vector_seconds = dt * np.arange(n_samples)
    time_vector_nanoseconds = (np.round(1e9 * time_vector_seconds)).astype(int)
    # time_vector_nanoseconds = int(np.round(1e9*time_vector_seconds))
    time_index_1 = np.array([t0 + np.timedelta64(x, 'ns') for x in time_vector_nanoseconds])
    processing_time_1 = tt - time.time()
    print(f"{processing_time_1}")
    # </SLOW>

    # <FAST>
    tt = time.time()
    dt_nanoseconds = int(np.round(1e9 * dt))
    dt_timedelta = np.timedelta64(dt_nanoseconds, 'ns')
    time_index_2= t0 + np.arange(n_samples) * dt_timedelta
    processing_time_2 = tt - time.time()
    print(f"{processing_time_2}")
    print(f"{processing_time_1/processing_time_2}")
    # </FAST>
    return time_index_1



def test_initialize_multivariate_time_series():
    n_samples = int(1e3); n_ch = 3#works for n_ch=1
    channel_labels = ["Hx", "Hy", "Hz"]
    sampling_rate = 3.0 #Hz
    t0 = pd.Timestamp(2021, 4, 4, 14, 20, 44)
    time_axis = test_generate_time_axis(t0, n_samples, sampling_rate)
    data = np.random.random((n_samples, n_ch))
    xrd = xr.DataArray(data, dims=["time", "channel"],
                       coords={"time": time_axis, "channel": channel_labels[:n_ch]})
    for channel_label,group in xrd.groupby("channel"):
        print(channel_label)
        print(type(group))

    #<DATA ACCESS>
    hx = xrd.loc[:, 'Hx']

    #</DATA ACCESS>
    mvts = MultiVariateTimeSeries(sampling_rate=sampling_rate, xarray=xrd)
    return mvts
    
#     print("ok")
#     #pd.DatetimeIndex()
#     #t0 = np.daa.Timestamp(2021, 4, 4, 14, 20, 44)
# #    time_axis = pd.date_range(t0, periods=10, freq=1.0)
# 
#     mvts = MultiVariateTimeSeries(sps=10.0, data=np.random.randn(111))
#     return mvts


def test_apply_windowing_to_mvts():
    mvts = test_initialize_multivariate_time_series()
    from iris_mt_scratch.sandbox.time_series.windowing_scheme_aurora import WindowingScheme
    windowing_scheme = WindowingScheme(num_samples_window=128, num_samples_overlap=64, taper='hamming')
    

def main():
    ts = test_multivariate_time_series()
    print('ok')

if __name__ == "__main__":
    main()

