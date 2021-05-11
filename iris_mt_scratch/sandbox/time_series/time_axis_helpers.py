import numpy as np
import pandas as pd
import time


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


def do_some_tests():
    n_samples = 1000
    sampling_rate = 50.0  # Hz
    t0 = pd.Timestamp(1977, 3, 2, 6, 1, 44)
    time_axis = test_generate_time_axis(t0, n_samples, sampling_rate)
    print(time_axis)

def main():
    do_some_tests()


if __name__ == "__main__":
    main()
