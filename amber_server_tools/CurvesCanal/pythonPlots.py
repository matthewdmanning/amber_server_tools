import glob

import matplotlib.font_manager
import pandas as pd
from pylab import *

rcParams.update({'figure.autolayout': True})
rcParams['legend.numpoints'] = 1
font = {'size': 20}

matplotlib.rc('font', **font)

base_pair_buffer = 10


class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)


def makeTimeFig(filename, name):
    curves_output = pd.read_csv(filename, header=None, delimiter="\s+")
    print(str(filename))
    print(curves_output)
    waitforbuttonpress()
    nucleic_length = curves_output.shape[1] - 1
    npMatrix = curves_output.as_matrix()
    bp_params_raw = npMatrix[:, 1:nucleic_length + 1]
    # Filter out NaN entries
    bp_params_nonan = bp_params_raw[~np.isnan(bp_params_raw)]
    # Stats on data.
    start_index = base_pair_buffer
    end_index = nucleic_length - base_pair_buffer + 1
    vmin = bp_params_nonan[start_index:end_index].min()
    vmax = bp_params_nonan[start_index:end_index].max()
    Y = npMatrix[:, 0]
    X = range(start_index, end_index)
    fig = plt.figure(figsize=(10, 12))
    font = {'size': 20}
    matplotlib.rc('font', **font)
    ax = fig.add_subplot(111)
    plt.xlabel("Base Index", fontsize=24)
    plt.ylabel("Frame", fontsize=24)
    plt.tick_params(
        axis='x',
        which='both',
        bottom='on',
        labelbottom='on')
    plt.title(filename)

    # ax.set_ylim([0,18000])
    # plt.xticks(np.arange(0,110,10))
    # plt.yticks(np.arange(0,18000,2000))
    # ax.set_yticklabels(np.arange(0,180,20))
    ax.set_xlim([1, nucleic_length])
    # ax.set_xticklabels(['A','T','C','A','A','T','A','T','C','C','A','C','C','T','G','C','A','G','A','T','T','C','T','A','C','C','A','A','A','A','G','T','G','T','A','T','T','T','G','G','A','A','A','C','T','G','C','T','C','C','A','T','C','A','A','A','A','G','G','C','A','T','G','T','T','C','A','G','C','T','G','A','A','T','T','C','A','G','C','T','G','A','A','C','A','T','G','C','C','T','T','T','T','G','A','T','G','G','A','G'])
    CP1 = plt.pcolormesh(bp_params_raw, vmin=vmin, vmax=vmax)
    CS1 = plt.colorbar(CP1, orientation='horizontal', shrink=0.8, format='%.1f', use_gridspec=True)
    plt.savefig(name, type='png', dpi=150)
    plt.close()


with cd("./"):
    rcParams.update({'figure.autolayout': True})

    font = {'size': 20}

    matplotlib.rc('font', **font)
    series_files = glob.glob('*.ser')
    levels = np.linspace(0.5, 15, 100)

for series_output in series_files:
    output_name = str(series_output)
    png_name = output_name.replace('.ser', '_heat.png')
    makeTimeFig(output_name, png_name)
