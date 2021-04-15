
import matplotlib.pyplot as plt
import os
import pandas as pd

file_basename = '3914.csv'
folder = "/home/kkappler/Documents/IRIS_MT"
file_path = os.path.join(folder, file_basename)

df = pd.read_csv(file_path)

base = df[df["is_base_frequency"]==1]
f_base = df['frequency']
ampl_base = df['amplitude']
phase_base = df['phase']

f = df['frequency']
ampl = df['amplitude']
phase = df['phase']

fig, ax = plt.subplots(2,1,1)
ax[0].plot(f, ampl)
plt.show()

