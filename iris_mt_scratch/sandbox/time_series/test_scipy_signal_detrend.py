"""
03 June 2021
We want to support the following options for the FFT
1. Linear detrending
2. mean-subtraction
3. no adulteration whatsoever

Rather than code these options,  it looks like scipy.signal.detrend already
supports this with options detrend="linear" and detrend="constant",
I want to make sure that if I pass it None it does nothing.


This was handy:
https://stackoverflow.com/questions/4805048/how-to-get-different-colored-lines-for-different-plots-in-a-single-figure

"""
import matplotlib.pyplot as plt
import numpy as np
import scipy.signal as ssig



def test_detrending():
    n_observations = 20
    n_channels = 3
    time_series = np.random.random((n_observations,n_channels))
    time_axis = np.arange(n_observations)

    slopes = [1,-2,3]
    intercepts = [1, -2, 3]
    for i_ch in range(n_channels):
        time_series[:,i_ch] += slopes[i_ch]*time_axis + intercepts[i_ch]

    detrend_options = ["linear", "constant", None]


    for detrend_option in detrend_options:
        ttl_str = f"{detrend_option}"
        #plt.gca().set_color_cycle(['red', 'green', 'blue'])
        plt.gca().set_prop_cycle(plt.cycler('color', ['red', 'green', 'blue']))
        plt.plot(time_axis, time_series)#, color="rbg")#["r", "b", "g"])
        plt.legend(["a","b","c"])

        detrended_data = ssig.detrend(time_series, axis=0, type=detrend_option)
        #plt.gca().set_color_cycle(['red', 'green', 'blue'])
        plt.plot(time_axis, detrended_data, time_series)
        plt.legend(["a", "b", "c"])
        plt.show()





def main():
    test_detrending()

if __name__ == "__main__":
    main()
