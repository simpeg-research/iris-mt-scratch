"""

We need to
1. initialize a MVTS [At a Decimation Level]
2. window the MVTS (channel by channel)
3. Taper the windowed MVTS
4. FT the tapered windows
5. Apply Window Scaling factors
6. Apply Calibration to SI units
7. Send Calibrated Time Series into TF Estimation Program
8.


The Problem with Decimation:  It is most efficient if the level immediately above it is available, but
for that to be the case you need to 
"""
#<FOURIER TRANSFORM CONFIG>
window_length = 128
taper_family = 'hamming'

window_overlap = 64

# window_length = 128
# window_overlap = 64
# taper_family = 'user-defined'
# taper = [1., 2., 3. , 2., 1. ]
#</FOURIER TRANSFORM CONFIG>




