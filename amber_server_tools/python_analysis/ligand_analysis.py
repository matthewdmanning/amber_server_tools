### This script analyzes and visualizes cpptraj output data of individual ligands.

import glob
import os

import matplotlib.font_manager
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib import rcParams


class context_working_dir_manager:
    """Context manager for changing the current working directory"""

    def __init__(self, new_path):
        self.newPath = os.path.expanduser(new_path)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)


with context_working_dir_manager("./"):
    rcParams.update({'figure.autolayout': True})

    font = {'size': 20}
    matplotlib.rc('font', **font)

    systems = glob.glob('*/')
    data_files_list = glob.glob('*lig*.dat')
    for data_file in data_files_list:
        cpp_df = pd.read_fwf(data_file, skiprow=lambda n: n % 50 == 0)  # , delim_whitespace=True)
        print('Dataframe loaded...\n')
        rog_df = cpp_df.filter(regex='*[Max]', axis=1)
        rog_df.mean(axis=0).plot()
        plt.show()
        print(rog_df.head())
        rog_df.plot.kde()
        plt.show()
        print('You should have gotten the KDE by now...\n')
