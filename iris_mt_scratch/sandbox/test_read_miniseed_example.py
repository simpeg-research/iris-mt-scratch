
import matplotlib.pyplot as plt
import obspy
import os

from obspy import read

data_dir = '/home/kkappler/.cache/iris_mt/datarepo/data/ZU/2020/188'
file_handle = 'UTS14.ZU.2020.188'
full_file_name = os.path.join(data_dir, file_handle)

from obspy import read

st = read(full_file_name)

print(st)

print(st[0].stats)
print(st[1].stats)

for k, v in sorted(st[0].stats.mseed.items()):
    print("'%s': %s" % (k, str(v)))

print(st[2].stats)

for i in range(len(st)):
    plt.plot(st[i], label='{}'.format(i))
    plt.legend()
plt.show()
print('hooray')

