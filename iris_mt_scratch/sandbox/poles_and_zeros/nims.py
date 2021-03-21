import numpy as np
# NIMS FILTERS
#   These values are from here:
#   http://service.iris.edu/fdsnws/station/1/query?net=EM&sta=IDA11&cha=*&level=response&format=xml&nodata=404
#   ALSO can pull these from an sp file (gains are clearer in sp files)

# B fields, one filter:
zeros_Blowpass = []
poles_Blowpass = [-6.28319 + 10.8825j, -6.28319 - 10.8825j, -12.5664]
gain_Blowpass = 1984.31
NIMS_Magnetic_3PoleLowpass = \
    signal.ZerosPolesGain(zeros_Blowpass, poles_Blowpass, gain_Blowpass)

# E fields, two filters:
zeros_Ehighpass = [0.]
poles_Ehighpass = [-1.66667E-4]
gain_Ehighpass = 1.
NIMS_Electric_Highpass = \
    signal.ZerosPolesGain(zeros_Ehighpass, poles_Ehighpass, 
                          gain_Ehighpass)

zeros_Elowpass = []
poles_Elowpass = [-3.88301 + 11.9519j, -3.88301 - 11.9519j, 
                  -10.1662 + 7.38651j, -10.1662 - 7.38651j, 
                  -12.5664]
gain_Elowpass = 313384.
NIMS_Electric_5PoleLowpass = \
    signal.ZerosPolesGain(zeros_Elowpass, poles_Elowpass, gain_Elowpass)
