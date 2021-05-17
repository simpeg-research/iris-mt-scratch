import numpy as np
import xarray as xr

from windowing_scheme import WindowingScheme

#<TESTS>
def test_instantiate_windowing_scheme():
    ws = WindowingScheme(num_samples_window=128, num_samples_overlap=32, num_samples_data=1000,
                         taper_family='hamming')
    ws.sampling_rate = 50.0
    print(ws.window_duration)
    print("assert some condtion here")
    return

def test_apply_sliding_window():
    N = 10000
    qq = np.random.random(N)
    windowing_scheme = WindowingScheme(num_samples_window=64, num_samples_overlap=50)
    print(windowing_scheme.num_samples_advance)
    print(windowing_scheme.available_number_of_windows(N))
    ww = windowing_scheme.apply_sliding_window(qq)
    return ww

def test_apply_sliding_window_can_return_xarray():
    qq = np.arange(15)
    windowing_scheme = WindowingScheme(num_samples_window=3, num_samples_overlap=1)
    ww = windowing_scheme.apply_sliding_window(qq, return_xarray=True)
    print(ww)
    return ww

def test_apply_sliding_window_to_xarray(return_xarray=False):
    N = 10000
    xrd = xr.DataArray(np.random.randn(N), dims=["time", ],
                       coords={"time": np.arange(N)})
    windowing_scheme = WindowingScheme(num_samples_window=64, num_samples_overlap=50)
    ww = windowing_scheme.apply_sliding_window(xrd, return_xarray=return_xarray)
    print("Yay!")
    return ww


def test_can_apply_taper():
    import matplotlib.pyplot as plt
    N = 10000
    qq = np.random.random(N)
    windowing_scheme = WindowingScheme(num_samples_window=64, num_samples_overlap=50,
                                       taper_family="hamming")
    print(windowing_scheme.num_samples_advance)
    print(windowing_scheme.available_number_of_windows(N))
    windowed_data = windowing_scheme.apply_sliding_window(qq)
    print("get taper")
    tapered_windowed_data = apply_taper_to_windowed_array(windowing_scheme.taper, windowed_data)
    plt.plot(windowed_data[0],'r');plt.plot(tapered_windowed_data[0],'g')
    plt.show()
    print("ok")
    return

def test_can_create_xarray_dataset_from_several_sliding_window_xarrays():
    """
    This method is going to create a bunch of xarray
    Returns
    -------
ds = xr.Dataset(
   ....:     {
   ....:         "temperature": (["x", "y", "time"], temp),
   ....:         "precipitation": (["x", "y", "time"], precip),
   ....:     },
   ....:     coords={
   ....:         "lon": (["x", "y"], lon),
   ....:         "lat": (["x", "y"], lat),
   ....:         "time": pd.date_range("2014-09-06", periods=3),
   ....:         "reference_time": pd.Timestamp("2014-09-05"),
   ....:     },
   ....: )
   ....:
    """
    from iris_mt_scratch.sandbox.time_series.time_axis_helpers import make_time_axis
    N = 1000
    t0 = np.datetime64("1977-03-02 12:34:56")
    time_vector = make_time_axis(t0, N, 50.0)
    windowing_scheme = WindowingScheme(num_samples_window=32, num_samples_overlap=8,
                                       taper_family="hamming")
    print("ok, now make a few xarrays, then bind them into a dataset")
    ds = xr.Dataset(
        {
            "hx" : (["time",], np.random.randn(N)),
            "hy": (["time", ], np.random.randn(N)),
        },
        coords={
            "time":time_vector,
            "some random info": "dogs",
            "some more random info": "cats"
        },
    )
    windowing_scheme.apply_sliding_window(ds)
    print("ok")
    pass

def test_fourier_transform():
    """
    This method needs to get a windowed time series, apply the taper,
    fft, scale the Fourier coefficients
    Returns
    -------

    """
    pass
#</TESTS>

def main():
    """
    Testing the windowing scheme
    """
    test_instantiate_windowing_scheme()
    np_out = test_apply_sliding_window()
    xr_out = test_apply_sliding_window_can_return_xarray()
    ww = test_apply_sliding_window_to_xarray(return_xarray=False)
    xr_out = test_apply_sliding_window_to_xarray(return_xarray=True)
    qq = test_can_create_xarray_dataset_from_several_sliding_window_xarrays()
    test_can_apply_taper()
    print("@ToDo Insert an integrated test showing common usage of sliding window\
    for 2D arrays, for example windowing for dnff")
    print("finito")

if __name__ == "__main__":
    main()