"""
ToDo: make a version of this that bases on xarray
"""

import numpy as np


class TimeSeries():
    """
    Generic class for handling time series.  Currently I am just thinking about 1D and this
    maybe better defined as UnivariateTimeSeries.  This is just a base for other time series with
    methods we will often want.
    User can provide one of dt, sps
    Although the init method does not require data, this class is intended to be used for 
    the case of time series that have data.  If it is not provided at init by a kwarg
    then it will typically be generated in the init method of the class extending this base.
    """

    def __init__(self, **kwargs):
        kwargs = self.validate_kwargs(**kwargs)
        self.sampling_rate = kwargs.get('sps', None)
        self.data = kwargs.get('data', None)
        # if self.data is not None:
        self._duration = kwargs.get('duration', None)
        # self.data
        self._time_vector = None

    def validate_kwargs(self, **kwargs):
        """
        check for duplicate definintions, e.g. (sps & dt), (data & duration),

        Parameters
        ----------
        kwargs

        Returns
        -------

        """
        #<sps, dt handler>
        sps = kwargs.get('sps', None)
        dt = kwargs.get('dt', None)
        if (sps is not None) and (dt is not None):
            print("Duplicate definition of sampling rate: this shouldn't happen")
            raise Exception

        if sps is None:
            if dt is None:
                print("you didn't define sampling rate ... ")
                print("not sure yet if I should raise an exception or set sps=1.0")
                raise Exception
            if dt is not None:
                kwargs['sps'] = 1./dt
                kwargs.__delitem__('dt')
        #</sps, dt handler>

        #<data, duration handler>
        print("WRITE A data / duration ingest handler")
        """
        This is actually a little bit tricky. There are cases where we would want to 
        define a time series by giving it a duration, and then let the data generate according
        to some process.  But there are other cases where we want to pass data and let the 
        duration be defined in terms of the sampling rate and the data itself.
        In the first case duration becomes a defined property.
        In the second case it is a derived property
        We could use _duration for the definition, and if _duration is None return 
        """
        data = kwargs.get('data', None)
        duration = kwargs.get('duration', None)
        if (data is None) and (duration is None):
            print("Time series has no data or duration, Probably not a good situation.")
            print("Not sure if we should raise exception ... or let user construct it... ")
            raise Exception
        if (data is not None) and (duration is not None):
            print("Duplicate definition of sampling rate: this shouldn't happen")
            raise Exception
        #</data, duration handler>
        return kwargs


    def validate(self):
        """
        check a few conditions to catch bad English:
        If sampling_rate and dt were provided, give a warning, and check that they
        are consistent, i.e. 1/sps=dt, else throw exception
        If dt is provided, store as sampling rate,
        If dt is zero throw an exception
        Returns
        -------

        """
        pass

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

    def _update(self):
        """
        Run a sequence of consistency checks
        Returns
        -------

        """
        pass



def test_time_series():
    ts = TimeSeries(dt=0.1, data=np.random.randn(111))
    return ts


def main():
    ts = test_time_series()
    print('ok')

if __name__ == "__main__":
    main()

