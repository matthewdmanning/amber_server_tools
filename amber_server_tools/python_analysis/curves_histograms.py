import glob
import os
from decimal import *

import numpy as np
import pandas as pd

getcontext().prec = 5
files_path = './'
files_substring = 'rog_nomax*.dat'
first_is_index = True
positive_only = True
output_name = 'summary.csv'
# Define first row to begin using data.
burn_in = 10
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


mean_list, stddev_list, percentile_list, system_list = [], [], [], []
with cd(files_path):
    files_list = glob.glob('*pro*.ser')  # .format(files_path, files_substring))
    number_of_files = len(files_list)
    summary_df = pd.DataFrame(np.nan, index=files_list, columns=['mean', 'std_dev', percentile_list[:]])
    for data_file in files_list:
        print('{}\n'.format(str(data_file)))
        data_array = np.genfromtxt(data_file)
        # print('There are a total of {} columns in this file.\n'.format(whole_rg_array.shape[1]))
        # if whole_rg_array.shape[1] == 2:
        index_list = np.copy(data_array[:, 0])
        series_array = data_array[burn_in:, 1:]
        median = np.nanpercentile(series_array, 50, axis=0)
        for value in median:
            print('{:.7}'.format(value))
        data_array = data_array[burn_in:, 1:].flatten()
        if positive_only:
            positive_array = data_array[data_array > 0]
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
