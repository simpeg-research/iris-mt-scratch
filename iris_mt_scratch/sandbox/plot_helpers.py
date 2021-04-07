import matplotlib.pyplot as plt
import numpy as np

def plot_complex_response(frequency, complex_response, **kwargs):
    """
    ToDo: add methods for suporting instrument object but for now take as kwargs
    :param frequency: numpy array of frequencies at which complex response is defined
    :param complex_response: numpy array of full complex valued response function
    :param kwargs:
    :return:
    """

    show = kwargs.get('show', True)
    linewidth = kwargs.get('linewidth', 3)

    make = kwargs.get('make', None)
    model = kwargs.get('model', None)
    y_amp_string = kwargs.get('yamp', None)

    amplitude = np.abs(complex_response)
    phase = np.angle(complex_response)

    plt.figure(1);
    #plt.clf()
    ax1 = plt.subplot(2,1,1)
    ax1.loglog(frequency, amplitude, linewidth = linewidth)
    ax1.set_title("{}-{}    Amplitude Response".format(make, model))
    ax1.grid(True, which="both", ls="-")
    ax1.set_ylabel("{}".format(y_amp_string))
    y_lim = ax1.get_ylim();
    ax1.set_ylim((y_lim[0], 1.1*y_lim[1]))
    ax2 = plt.subplot(2,1,2)
    ax2.semilogx(frequency, phase, linewidth = linewidth)
    ax2.set_title("{}-{}    Phase Response".format(make, model))
    ax2.grid(True,which="both",ls="-")
    if show:
        plt.show()