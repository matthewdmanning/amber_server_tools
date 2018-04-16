import glob

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def get_eigenvalues(file_name):
    eigenvalues_tuple = []
    with open(file_name, 'r') as principal_file:
        for line in principal_file:
            if 'EIGENVALUES' in line:
                eigenvalues_tuple.append(line.split()[2:5])
            else:
                continue
    eigenvalue_array = np.array(eigenvalues_tuple)
    return eigenvalue_array


# https://github.com/sciapp/pyMolDyn/
# Input should be 2-D numpy array consisting of principal moments/eigenvalues of points
def calculate_relative_shape_anisotropy(eigenvalues_array):
    squared_gyration_radius = sum(eigenvalues_array)
    if squared_gyration_radius > 0:
        asphericity = calculate_asphericity(eigenvalues_array)
        anisotropy = (asphericity ** 2 + 0.75 * acylindricity ** 2) ** 0.5
    else:
        anisotropy = 0
    return anisotropy


def calculate_asphericity(eigenvalues_array):
    # squared_gyration_radius = sum(eigenvalues_array)
    # if squared_gyration_radius > 0:
    asphericity = (eigenvalues_array[0] - 0.5 * (eigenvalues_array[1] + eigenvalues_array[2])) / squared_gyration_radius
    # else:
    #    asphericity = 0
    return asphericity


def acylindricity(eigenvalues_array):
    # squared_gyration_radius = sum(eigenvalues_array)
    # if squared_gyration_radius > 0:
    acylindricity = (eigenvalues_array[1] - eigenvalues_array[2]) / squared_gyration_radius
    # else:
    #    acylindricity = 0
    return acylindricity


principal_files_list = glob.glob('*principal*.dat')
for data_file in principal_files_list:
    eigenvalues = get_eigenvalues(data_file)
    anisotropy_array = calculate_relative_shape_anisotropy(eigenvalues)

filename = '~/mnt9/corona0-80/dodec-0/etoe.dat'
phodf = pd.read_table(filename, delimiter=r'\s*', engine='python')
phodf = phodf.set_index('#Frame')
print
phodf.head()
print
phodf.shape
# endax = phodf.plot.box(showfliers=False,whis=[5,95],showmeans=True,meanline=True)
phodf.mean().plot(legend=True, label='100% Dodecane')
# plt.show()
filename = 'etoe-phi.dat'
phidf = pd.read_table(filename, delimiter=r'\s*', engine='python')
phidf = phidf.set_index('#Frame')
print
phidf.head()
print
phidf.shape
phidf.mean().plot(legend=True, label='100% PEG3-ethylamine')

filename = '~/mnt9/corona100/undecguan-100/etoe-phi.dat'
guandf = pd.read_table(filename, delimiter=r'\s*', engine='python')
guandf = guandf.set_index('#Frame')
print
guandf.head()
print
guandf.shape
guandf.mean().plot(legend=True, label='100% Undecylguanidine')
# plt.show()

plt.show()
