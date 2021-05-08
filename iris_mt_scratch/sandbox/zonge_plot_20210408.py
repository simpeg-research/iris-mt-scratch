import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
matplotlib.rc('text', usetex = True)
plt.ioff()
#matplotlib.pyplot.grid(True, which="both")

file_basename = '3914.csv'
folder = "/home/kkappler/Documents/IRIS_MT/calibration_files/from_andy_08_april"
file_path = os.path.join(folder, file_basename)
#andy_file_path = os.path.join(folder, '3914_andy.csv')
df_andy = pd.read_csv(os.path.join(folder, '3914_andy.csv'))
df_paul = pd.read_csv(os.path.join(folder, '3914_paul.csv'))
df_karl = pd.read_csv(os.path.join(folder, '3914_karl.csv'))

df = pd.read_csv(file_path)
df['phase'] = df['phase']/1000.0#radians
df['phase'] = df['phase']*180/3.14159 #degrees
df = df.sort_values(by=['frequency'])

#logf = np.log10(f)
#f = df['frequency']

base_df = df[df["is_base_frequency"]==1]
f_base = base_df['frequency']
ampl_base = base_df['amplitude']
phase_base = base_df['phase']

harmonic_df = df[df["is_base_frequency"]==0]
f_harmonic = harmonic_df['frequency']
ampl_harmonic = harmonic_df['amplitude']
phase_harmonic = harmonic_df['phase']
f = df['frequency']
ampl = df['amplitude']
phase = df['phase']

#fig, ax = plt.subplot(2,1,1)
fig, ax = plt.subplots(nrows=2, sharex=True)
ax[0].semilogx(f, ampl)
ax[0].semilogx(f_base, ampl_base, 'ro', label='base $f$')
ax[0].semilogx(f_harmonic, ampl_harmonic, 'bo', label='harmonic $f$')
ax[0].semilogx(df_andy["freq"], df_andy["amp"], 'k', label='andy')
ax[0].semilogx(df_paul["freq"], df_paul["amp"], 'b*', label='paul', markersize=14)
ax[0].semilogx(df_karl["freq"], df_karl["amp"], 'co', label='karl')
ax[0].set_ylabel("Amplitude $\mu$V/nT ")
ax[0].grid(True, which="both")
ax[0].legend()
ax[1].semilogx(f, phase)
ax[1].semilogx(f_base, phase_base, 'ro')
ax[1].semilogx(f_harmonic, phase_harmonic, 'bo')
ax[1].set_ylabel("Phase (degrees)")
ax[1].set_xlabel("Frequency (Hz)")
ax[1].grid(True, which="both")
ax[0].set_title("Response for Coil 3914")
plt.show()

