import os
from decimal import *

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

getcontext().prec = 5
files_path = '/'
glob_pattern = 'rog_nomax*.dat'
first_is_index = True
positive_only = True
output_name = 'summary.csv'
# Define first row to begin using data.
remove_outliers = False

class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os


def reject_outliers_stddev(data, z_score_cutoff=2, std_dev=np.nan):
    if std_dev == np.nan:
        std_dev = np.nanstd(data)
    return data[abs(data - np.mean(data)) < z_score_cutoff * std_dev]


def reject_outliers_multiple(data, multiplier=2, median=np.nan):
    if median == np.nan:
        median = np.nanpercentile(data, 50)
    return data[data - multiplier * median < 0.001]


def make_histogram(data_array):
    percentile_list = [0, 25, 50, 75, 100]
    mean_values = np.nanmean(data_array)
    quartiles = np.nanpercentile(data_array, percentile_list, axis=0)
    std_dev_array = np.nanstd(data_array, axis=0)
    print('Mean values are: {}\n'.format(mean_values))
    print('Quartile values are: {}\n'.format(quartiles))
    print('Standard deviations are: {}\n'.format(std_dev_array))
    return mean_values, std_dev_array, quartiles


def multi_histogram(data_array):
    fig, ax = plt.subplots()
    for a in data_array[:, 1:]:
        sns.distplot(a, bins=250, ax=ax, kde=False)
    #ax.set_xlim([0, 100])
    plt.show()

mean_list, stddev_list, percentile_list, system_list = [], [], [], []
with cd(files_path):
    #files_list = glob.glob(glob_pattern)  # .format(files_path, files_substring))
    #number_of_files = len(files_list)
    #summary_df = pd.DataFrame(np.nan, index=files_list, columns=['mean', 'std_dev', percentile_list[:]])
    # H4 Tails in whole nucleosome.
    whole_burn = 2500
    whole_rg_file = 'rog_nomax.tails.1kx5.dat'
    whole_rg_array = np.genfromtxt(whole_rg_file)
    whole_timestep = np.copy(whole_rg_array[whole_burn:, 0])
    whole_rog_array = whole_rg_array[whole_burn:, 1:]
    whole_e2e_file = 'e2e.tails.1kx5.dat'
    whole_e2e = np.genfromtxt(whole_e2e_file)
    whole_e2e_array = np.copy(whole_e2e[whole_burn:, 1:])

    # Tail attached to dummy sphere
    tether_burn = 50000
    tethered_rg_file = 'rog.H4.prod1-73.dat'
    tethered_rg_array = np.genfromtxt(tethered_rg_file)
    tethered_timestep = np.copy(tethered_rg_array[tether_burn:, 0])
    tethered_rog_array = np.copy(tethered_rg_array[tether_burn:, 1])
    tethered_e2e_file = 'e2e.H4.prod1-73.dat'
    tethered_e2e = np.genfromtxt(tethered_e2e_file)
    tethered_e2e_array = np.copy(tethered_e2e[tether_burn:, 1])

    # Tail Free in OPC Solution
    free_burn = 50000
    free_rg_file = 'ROG-H4-Free-Tail.dat'
    free_rg_array = np.genfromtxt(free_rg_file)
    free_timestep = np.copy(free_rg_array[free_burn:, 0])
    free_rog_array = np.copy(free_rg_array[free_burn:, 1])
    free_e2e_file = 'ETE-H4-Free-Tail.dat'
    free_e2e = np.genfromtxt(free_e2e_file)
    free_e2e_array = np.copy(free_e2e[free_burn:, 1])

    # Long Run - Quarter 1kx5 Nucleosome - Chain F
    long_quarter_burn = 2500
    long_quarter_rg_file = 'ROG-H4-Attach-to-quarter-long-run-ChainG.dat'
    long_quarter_rg_array = np.genfromtxt(long_quarter_rg_file)
    long_quarter_timestep = np.copy(long_quarter_rg_array[long_quarter_burn:, 0])
    long_quarter_rog_array = np.copy(long_quarter_rg_array[long_quarter_burn:, 1])
    long_quarter_e2e_file = 'ROG-H4-Attach-to-quarter-long-run-ChainG.dat'
    long_quarter_e2e = np.genfromtxt(long_quarter_e2e_file)
    long_quarter_e2e_array = np.copy(long_quarter_e2e[long_quarter_burn:, 1])

    # Short Run Quarter 1kx5 Nucleosome - Chain F
    short_quarter_burn = 2500
    short_quarter_rg_file = 'ROG-H4-Attach-to-quarter-short-run.dat'
    short_quarter_rg_array = np.genfromtxt(short_quarter_rg_file)
    short_quarter_timestep = np.copy(short_quarter_rg_array[short_quarter_burn:, 0])
    short_quarter_rog_array = np.copy(short_quarter_rg_array[short_quarter_burn:, 1])
    short_quarter_e2e_file = 'ETE-H4-Attach-to-quarter-short-run.dat'
    short_quarter_e2e = np.genfromtxt(short_quarter_e2e_file)
    short_quarter_e2e_array = np.copy(short_quarter_e2e[short_quarter_burn:, 1])

    # H4 Tail in Implicit Solvent
    implicit_burn = 50000
    implicit_rg_file = 'rog.H4-implicit.dat'
    implicit_rg_array = np.genfromtxt(implicit_rg_file)
    implicit_timestep = np.copy(implicit_rg_array[implicit_burn:, 0])
    implicit_rog_array = np.copy(implicit_rg_array[implicit_burn:, 1])
    #implicit_e2e_file = ''
    #implicit_e2e = np.genfromtxt(implicit_e2e_file)
    #implicit_e2e_array = np.copy(implicit_e2e[implicit_burn:, 1])
    # print('There are a total of {} columns in this file.\n'.format(whole_rg_array.shape[1]))
    # if whole_rg_array.shape[1] == 2:
    #df_data = pd.DataFrame(whole_rg_array)

    #sns.tsplot(df_data, time=df_data.iloc[:,0])
    whole_time_ns = whole_timestep / 40.
    tether_time_ns = tethered_timestep / 40.
    quarter_time_ns = long_quarter_timestep / 40.
    implicit_time_ns = implicit_timestep / 40.
    plt.style.use('seaborn-poster')
    #plt.style.use('ggplot')

    '''
    with plt.style.context('seaborn-dark-palette'):
        fig = plt.figure()
        plt.xlabel('Time [ns]')
        plt.ylabel('Rg [Angstroms]')
        #ax1 = plt.subplot(411)
        ax1 = plt.subplot(221)
        plt.plot(whole_time_ns, whole_rog_array[:,0], label="H3 (Chain C)")
        plt.plot(whole_time_ns, whole_rog_array[:,3], label="H3 (Chain G)")
        plt.legend()
        plt.subplot(222, sharey=ax1)
        plt.plot(whole_time_ns, whole_rog_array[:,1], label="H4 (Chain D)")
        plt.plot(whole_time_ns, whole_rog_array[:,4], label="H4 (Chain H)")
        plt.legend()
        plt.subplot(223, sharey=ax1)
        plt.plot(whole_time_ns, whole_rog_array[:,2], label="H2A (Chain E)")
        plt.plot(whole_time_ns, whole_rog_array[:,5], label="H2A (Chain I)")
        plt.legend()
        plt.subplot(224, sharey=ax1)
        plt.plot(whole_time_ns, whole_rog_array[:,3], label="H2B (Chain F)")
        plt.plot(whole_time_ns, whole_rog_array[:,6], label="H2B (Chain J)")
        plt.legend()
        fig.set_facecolor('w')
        plt.show()
    '''
    plt.rcParams.update(plt.rcParamsDefault)
    #print(plt.style.available)
    with plt.style.context('seaborn-dark-palette'):
        plt.rcParams.update({'font.size': 16})

        shading=0.5
        # Histograms of R_g Distributions
        fig = plt.figure()
        rog_ax = plt.subplot(121)
        #plt.hist(whole_rog_array[:, 1], label='H4 Chain D - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(whole_rog_array[:, 4], label='H4 Chain G - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(tethered_rog_array, label='H4 Reverse Tethered OPC', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(long_quarter_rog_array, label='H4 Quarter 1kx5 - Long', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(short_quarter_rog_array, label='H4 Quarter 1kx5 - Short', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(free_rog_array, label='H4 Tail - Untethered OPC', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        #plt.hist(implicit_rog_array, label='H4 Tail - Implicit Solvent', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        fig.set_facecolor('w')
        plt.ylim([0,1.15])
        plt.xlim([7.5,25])
        plt.xlabel('Rg [Angstroms]')
        plt.ylabel('P(Rg)')
        #plt.gca().set_aspect('equal', adjustable='box')

        #plt.show()
        #plt.legend()
        #plt.show()

        e2e_ax = plt.subplot(122)
        #print(whole_e2e_array)
        #plt.hist(whole_e2e_array[:, 1], label='H4 Chain D - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(whole_e2e_array[:, 4], label='H4 Chain H - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(tethered_e2e_array, label='H4 Reverse Tethered', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(long_quarter_e2e_array, label='H4 Quarter 1kx5 - Long', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(short_quarter_e2e_array, label='H4 Quarter 1kx5 - Short', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        #plt.hist(implicit_e2e_array, label='H4 Tail - Implicit Solvent', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(free_e2e_array, label='H4 Tail - Untethered OPC', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        fig.set_facecolor('w')
        plt.ylim([0,0.8])
        plt.xlim([3,65])
        plt.tight_layout()
        plt.xlabel('H4 End-to-End Distance [Angstroms]')
        plt.ylabel('P(E2E)')
        #plt.gca().set_aspect('equal', adjustable='box')
        plt.draw()
        #rog_ax.set(adjustable='box-forced', aspect='equal')
        #e2e_ax.set(adjustable='box-forced', aspect='equal')
        plt.show()

        fig = plt.figure()
        ax1 = plt.subplot(221)
        plt.hist(whole_rog_array[:, 0], label='H3 Chain C - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(whole_rog_array[:, 3], label='H3 Chain G - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.legend()
        plt.subplot(222, sharey=ax1, sharex=ax1)

        plt.subplot(223, sharey=ax1, sharex=ax1)
        plt.hist(whole_rog_array[:, 2], label='H2A Chain E - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(whole_rog_array[:, 5], label='H2A Chain I - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.legend()
        plt.subplot(224, sharey=ax1, sharex=ax1)
        plt.hist(whole_rog_array[:, 3], label='H2B Chain E - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.hist(whole_rog_array[:, 6], label='H2B Chain I - Whole 1kx5', bins=100, histtype='stepfilled', normed=True, alpha=shading)
        plt.legend()
        fig.set_facecolor('w')
        plt.ylim([0,0.75])
        plt.xlim([7.5,30])
        plt.tight_layout()
        plt.xlabel('Rg [Angstroms]')
        plt.ylabel('P(Rg)')
        plt.show()

        multi_histogram(whole_rg_array)

        median = np.nanpercentile(whole_rog_array, 50, axis=0)
        for value in median:
            print('{:.7}'.format(value))
        whole_rg_array = whole_rg_array[whole_burn:, 1:].flatten()
        if positive_only:
            positive_array = whole_rg_array[whole_rg_array > 0]
        standard_dev = np.nanstd(positive_array)
        if remove_outliers:
            for outlier_loop in list(range(2)):
                median_val = np.nanpercentile(positive_array, 50)
                standard_dev = np.nanstd(positive_array)
                print('Median is {}'.format(median_val))
                print('Standard deviation is {}'.format(standard_dev))
                cleaned_data = reject_outliers_multiple(positive_array, median=median_val)
                positive_array = cleaned_data
            cleaned_data = reject_outliers_stddev(positive_array, z_score_cutoff=2, std_dev=standard_dev)
        else:
            cleaned_data = positive_array
        median_val = np.nanpercentile(cleaned_data, 50)
        standard_dev = np.nanstd(cleaned_data)
        print('Median is {}'.format(median_val))
        print('Standard deviation is {}'.format(standard_dev))
        mean_values, std_dev_array, quartiles = make_histogram(cleaned_data)
        system_list.append(str(data_file))
        mean_list.append(mean_values)
        stddev_list.append(std_dev_array)
        percentile_list.append(quartiles)
        # summary_df.loc[str(data_file),:] = mean_values, std_dev_array, quartiles[:]
    print(np.array(system_list).T)
    print('\nMeans')
    for value in mean_list:
        print('{:.7}'.format(value))
    # print(np.array(mean_list))
    print('\nStandard Deviations')
    for value in stddev_list:
        print('{:.7}'.format(value))
    # print(np.array(stddev_list))
    print('\nQuartiles')
    for value_list in percentile_list:
        print('\t\t'.join(['{:.7}'.format(value) for value in value_list]))

    with open(output_name, 'w') as file:
        file.write('System,Mean,StDev,Min,25,Median,75,Max\n')
        for system, mean, st_dev, percentiles in zip(system_list, mean_list, stddev_list, percentile_list):
            file.write(
                '{0},{1:.7},{2:.7},{3[0]:.7},{3[1]:.7},{3[2]:.7},{3[3]:.7},{3[4]:.7}\n'.format(system, mean, st_dev,
                                                                                               percentiles))
        file.close()
    # print(np.array(percentile_list))
    final_format = pd.DataFrame(
        [np.array(system_list), np.array(mean_list), np.array(stddev_list)])  # , np.array(percentile_list)])
    # np.savetxt('{}.csv'.format(output_name), final_format)
    # final_format.to_txt(output_name)
    # print(final_format)
    # print(mean_list, stddev_list, percentile_list)

    # else:
