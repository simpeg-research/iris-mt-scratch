import numpy as np
from time_series import TimeSeries

class Sinusoid(TimeSeries):
    def __init__(self, **kwargs):
        super(Sinusoid, self).__init__(**kwargs)
        self.amplitude = kwargs.get('amplitude', 1.0)
        self.frequency = kwargs.get('frequency', 1.0)
        self.generate_time_series()


    def generate_time_series(self):
        time_vector = self.time_vector
        data = self.amplitude * np.sin(2 * np.pi * self.frequency * self.time_vector)
        self.data = data
        return data

    def __str__(self):
        description = 'f={:.2f}Hz, '.format(self.frequency)
        return description


def test():
    A1 = 1.0; f1 = 1.0; sps=1000; T=10;
    sinusoid = Sinusoid(amplitude=A1, frequency=f1, sps=sps, duration=T)

def main():
    test()


if __name__ == '__main__':
    main()
