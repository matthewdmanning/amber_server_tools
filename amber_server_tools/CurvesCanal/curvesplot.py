import glob

import plotly as py
import plotly.graph_objs as go
import seaborn
import sklearn.neighbors
from pylab import *
from scipy import stats

rcParams['legend.numpoints'] = 1


# Compute the pdf/KDE. Taken from https://jakevdp.github.io/blog/2013/12/01/kernel-density-estimation/
def kde_sklearn(x, x_grid, bandwidth=0.2, **kwargs):
    """Kernel Density Estimation with Scikit-learn"""
    kde_skl = sklearn.neighbors.KernelDensity(bandwidth=bandwidth, **kwargs)
    kde_skl.fit(x[:, np.newaxis])
    # score_samples() returns the log-likelihood of the samples
    log_pdf = kde_skl.score_samples(x_grid[:, np.newaxis])
    return np.exp(log_pdf)


''' Relic function from Jessica's original script.
def converter(x):
    print(x)
    if "NA" in x or x == "NA":
        return np.nan
    else:
        try:
            number = float(x)
            return number
        except:
            return np.nan
'''


class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)


def check_periodic_param(param_file_abbrev):
    periodic_list = ['propel', 'opening', 'inclin', 'tip', 'ax-bend', 'tilt', 'roll', 'twist', 'h-twi']
    return param_file_abbrev in periodic_list


def get_full_param_name(param_file_name):
    filename_list = ['shear', 'stretch', 'stagger', 'buckle', 'propel', 'opening', 'xdisp', 'ydisp', 'inclin', 'tip',
                     'ax-bend', 'shift', 'slide', 'rise', 'tilt', 'roll', 'twist', 'h-ris', 'h-twi', 'minw', 'mind',
                     'majw', 'majd']
    parameter_list = ['Shear', 'Stretch', 'Stagger', 'Buckle', 'Propeller Twist', 'Opening', 'X Displacement',
                      'Y Displacement', 'Incline', 'Tip',
                      'Axial Bend', 'Shift', 'Slide', 'Rise', 'Tilt', 'Roll', 'Twist', 'Helical Rise', 'Helical Twist',
                      'Minor Groove Width', 'Minor Groove Depth',
                      'Major Groove Width', 'Major Groove Depth']
    param_dict = {key: value for (key, value) in zip(filename_list, parameter_list)}
    if param_file_name in filename_list:
        return param_dict[param_file_name]
    else:
        return param_file_name


### Define filename::parameter dictionary for Curves+ output.

path_list = ['/home/mdmannin/']
window_size = 50
bp_buffer = 5
polar_hist = True
recenter_periodic = True
save_plots = True


def canal_flattener(bp_param_matrix, param_name):
    try:
        # print(curves_output_file)

        # Create histogram and box and whisker plots from pooled data
        bp_param_flattened = bp_param_matrix.flatten()
        if bp_param_flattened.size <= 0:
            return np.array([]), np.array([]), []
        nan_count = np.count_nonzero(np.isnan(bp_param_flattened))
        nan_percent = 100 * nan_count / bp_param_flattened.size
        print('Percentage of invalid (NaN) entries: {}%.\n'.format(nan_percent))
        if nan_percent >= 50.:
            print("More than half of values are undefined. I'll keep on trying...\n")
            return np.array([]), np.array([]), 0
        bp_param_flattened = bp_param_flattened[~np.isnan(bp_param_flattened)]
        return bp_param_flattened, nan_count
    except:
        return np.array([]), np.array([]), 0


def check_if_data_periodic(data_array):
    lower_data_threshold = -50
    upper_data_threshold = 50
    if np.nanmin(data_array) < -50. and np.nanmax(data_array) > 50.:
        return True
    else:
        return False


# Recenters periodic data, such that the mode of the data is the start of the period.
# Performance note: This copy the data in all of the arrays. It's atrocious, but I don't have time to fix it right now.
def recenter_periodic_data(data_array, full_period=360):
    mode_params, mode_count = stats.mode(data_array, nan_policy='omit')
    print('The mode of this data is: {}\n'.format(mode_params[0]))
    centered_params_vector = data_array  # - mode_params[0]
    normalized_params_vector = []
    for param in centered_params_vector:
        if param < mode_params - full_period / 2:
            param += full_period
        elif param > mode_params + full_period / 2:
            param -= full_period
        normalized_params_vector.append(param)
    return np.array(normalized_params_vector)

    matplotlib.style.use('ggplot')


def canal_with_seaborn(base_pair_array_list, param_name, simulation_name_list=[]):
    seaborn.set()
    fig, ax = plt.subplots()
    for array_index, parameter_dist in enumerate(base_pair_array_list):
        if len(simulation_name_list) > 0:
            sim_label = str(simulation_name_list[array_index])
        else:
            sim_label = str(array_index + 1)

        seaborn.kdeplot(parameter_dist, ax=ax, label=sim_label)
    ax.set(title=get_full_param_name(param_name))
    ax.legend()
    plt.show()
    return


def simple_heatmap(data_array):
    plt.imshow(data_array, cmap='hot', interpolation='nearest')
    # Create the contour plot
    xi = list(range(data_array.shape[0]))
    yi = list(range(data_array.shape[1]))
    CS = plt.contourf(xi, yi, data_array, 15, cmap=plt.cm.rainbow)
    # vmax=zmax, vmin=zmin)
    # plt.colorbar()
    # nan_mask = whole_rg_array.isnull()
    # ax = seaborn.heatmap(whole_rg_array, mask=nan_mask)
    plt.show()


def canal_visualizer(base_pair_array_list, param_name, simulation_name_list=[]):
    # Determine if data is periodic or linear.
    full_param_name_list = []
    if polar_hist is True and check_periodic_param(param_name):
        print('Periodic data detected. Recentering each series based on their respective modes.\n')
        normalized_parameter_array_list = []
        if recenter_periodic:
            normalized_parameter_array_list = [recenter_periodic_data(param_array) for param_array in
                                               base_pair_array_list]
        else:
            normalized_parameter_array_list = [param_array for param_array in base_pair_array_list]
        # Descriptive stats for distribution.
        # Get bins for histograms by merging all data into one set.
        # bin_counts, combined_bin_edges = np.histogram(np.hstack(normalized_parameter_array_list))#, bins='fd')
        bin_counts, combined_bin_edges = np.histogram(normalized_parameter_array_list[0], bins='fd')
        num_bins = combined_bin_edges.size - 1
        # bin_centers_list = []
        # for bindex in list(range(combined_bin_edges.size())):
        #    bin_centers_list.append(combined_bin_edges[bindex] / 2. + combined_bin_edges[bindex+1] / 2.)
        # bin_center_array = np.array(bin_centers_list)
        param_median_list, param_mean_list, param_stddev_list = [], [], []
        # Plot each histogram on the same figure.
        hist_fig, hist_ax = plt.subplots()
        for array_index, parameter_array in enumerate(normalized_parameter_array_list):
            if len(simulation_name_list) > 0:
                sim_label = str(simulation_name_list[array_index])
            else:
                sim_label = str(array_index + 1)

            # print('Combined bin edges: {}.\n'.format(combined_bin_edges))
            # print('Data label: {}.\n'.format(sim_label))
            # print('Parameter array: {}.\n'.format(parameter_array))
            # print('Total number of bins to use: {}.\n'.format(num_bins))
            # plt.hist(parameter_array, bins = num_bins, normed=1, histtype='step', label=sim_label)
            plt.hist(parameter_array, bins='fd', normed=1, histtype='step', label=sim_label)
            print('{}: {}\n'.format(sim_label, np.nanmean(parameter_array)))
        # Formatting for histogram.
        full_param_name = get_full_param_name(param_name)
        full_param_name_list.append(full_param_name)
        hist_ax.set_title('{}'.format(full_param_name))
        plt.legend(loc='upper right', prop={'size': 8})
        if save_plots:
            figure_file_name = '{}.png'.format(full_param_name)
            plt.savefig(figure_file_name, dpi=300, format='png')
            plt.close()
        else:
            plt.show()
        print('Mean Values\n')
        for sim_label, parameter_array in zip(simulation_name_list, normalized_parameter_array_list):
            print('{}: {}\n'.format(sim_label, np.nanmean(parameter_array)))
        print('Median Values\n')
        for sim_label, parameter_array in zip(simulation_name_list, normalized_parameter_array_list):
            print('{}: {}\n'.format(sim_label, np.nanmedian(parameter_array)))
        print('Standard Deviation Values\n')
        for sim_label, parameter_array in zip(simulation_name_list, normalized_parameter_array_list):
            print('{}: {}\n'.format(sim_label, np.nanstd(parameter_array)))


'''            #print(bp_param_flattened)
        # Determine if data is linear or periodic/circular.
            # plt.hist(np.radians(bp_param_flattened), bins=np.arange(360), width=(2 * np.pi), normed=1, bottom = 0)
            # Use the mode to center the data for more continuous plotting.

            #print(centered_params_vector)

            # Calculate pdf of normalized data.
            # x_grid = np.linspace(np.nanmin(normalized_params_vector), np.nanmax(normalized_params_vector), 1000)
            # pdf = kde_sklearn(normalized_params_vector, x_grid, bandwidth=0.2)

            # circ_hist_ax = plt.subplot(131, projection='polar')
            gridspec1 = gridspec.GridSpec(4, 3)

            # Circular histogram for periodic data
            circ_hist_ax = plt.subplot2grid((4, 3), (0, 0), rowspan=2, colspan=2, projection='polar')
            polar_bin_counts, polar_bin_edges, polar_patches = plt.hist(np.radians(normalized_params_vector),
                                                                        bins='fd', normed=1, bottom=0)

            # Linear histogram centered at the mode of the data.
            linear_hist_ax = plt.subplot2grid((4, 3), (2, 0), rowspan=2, colspan=2)
            linear_bin_counts, linear_bin_edges, linear_patches = plt.hist(normalized_params_vector,
                                                                           histtype='step', bins='fd', normed=1)

            # Boxplot, again centered at the mode.
            box_ax = plt.subplot2grid((4, 3), (0, 2), rowspan=4, colspan=1)
            boxplot_summary = plt.boxplot(normalized_params_vector)

            # Set titles for each plot.
            circ_hist_ax.set_title('Histogram of {}'.format(param_name))
            linear_hist_ax.set_title('Histogram of {}'.format(param_name))
            box_ax.set_title('Boxplot of {}'.format(param_name))
            # Space for additional plot formatting.
            # gridspec1.tight_layout(fig)

            # Save raw array data to file for later use.
            for array_data, data_name in zip(
                    [polar_bin_counts, polar_bin_edges, linear_bin_counts, linear_bin_edges, boxplot_summary],
                    ['polar_bin_counts', 'polar_bin_edges', 'linear_bin_counts', 'linear_bin_edges',
                     'boxplot_summary']):
                file_out_name = '{}_{}'.format(param_name, data_name)
        else:
            hist_ax = plt.subplot(121)
            try:
                linear_bin_counts, linear_bin_edges, linear_patches = plt.hist(bp_param_flattened, histtype='step',
                                                                               normed=1, bins='fd')
            except ValueError:
                continue
            box_ax = plt.subplot(122)
            plt.boxplot(bp_param_flattened)

            hist_ax.set_title('Histogram of {}'.format(param_name))
            box_ax.set_title('Boxplot of {}'.format(param_name))

        hist_box_png_name = '{}_hist+box.png'.format(param_name)
        # plt.tight_layout(pad=0.4, w_pad=0.5, h_pad=1.0)

        plt.savefig(hist_box_png_name, dpi=300, format='png')
        plt.draw()
        plt.close()
'''


def plot_bp_errorbars(base_pair_indices_list, bp_means_list, bp_stderr_list, systems_list, full_param_name):
    # print(systems_list)
    # print(base_pair_indices_list)
    # print(bp_means_list)
    # print(bp_stderr_list)
    for base_pair_indices, bp_means, bp_stderr, system_name in zip(base_pair_indices_list, bp_means_list,
                                                                   bp_stderr_list, systems_list):
        # print(system_name)
        # print(base_pair_indices)
        # print(bp_means)
        print('Plotting {}\n'.format(system_name))
        # plt.plot(base_pair_indices, bp_means, label=system_name)
        plt.errorbar(base_pair_indices, bp_means, yerr=bp_stderr, label=system_name)
    plt.title(full_param_name)
    plt.legend()
    # plt.show()
    # plt.show()
    if save_plots:
        figure_file_name = '{}_bp_errorbar.png'.format(full_param_name)
        plt.savefig(figure_file_name, dpi=300, format='png')
    plt.close()


def plotly_boxplots(base_pair_indices, bp_params_array, system_name, show_bool=False):
    if len(base_pair_indices) == 0 or bp_params_array.size == 0:
        return False
    show_bool = False
    boxplot_tuple = []
    boxplot_file_name = '{}_boxplot.png'.format(system_name)
    for plot_num, base_pair_index in enumerate(base_pair_indices):
        new_plot = go.Box(x=bp_params_array[plot_num])
        boxplot_tuple.append(new_plot)
    # boxplot_url = py.plot(plot_tuple, file_name=boxplot_file_name, sharing='secret', auto_open=True)
    py.offline.plot(boxplot_tuple)
    if show_bool:
        plt.show()
    return boxplot_tuple


# def plotly_error_bars(base_pair_indices, bp_params_array, system_name, show_bool=False):
# error_bars_vector =
# chart_object = go.Scatter(x=base_pair_indices, y=bp_params_array, error_y=dict(type='data',array=))



def summarize_curves(param_file_list, input_system_name_list):
    for canal_output_file, system_name in zip(param_file_list, input_system_name_list):
        # Get parameter name from file.
        curves_matrix = np.genfromtxt(
            canal_output_file)  # , filling_values=np.nan)  # converters={1:converter, 2:converter})
        frame_num_vector = curves_matrix[:, 0]
        nucleic_length = curves_matrix.shape[1] - 1
        # Calculate PYTHON column indices of base pair parameters
        bp_buffered_start = bp_buffer + 1
        bp_buffered_end = nucleic_length - bp_buffer + 1
        # Make list of base pair indices (relative to starting with 1) and make matrix with only those base pairs included
        base_pair_indices = np.arange(bp_buffered_start, bp_buffered_end)
        base_pair_indices_list.append(base_pair_indices)
        bp_param_matrix = curves_matrix[:, bp_buffered_start:bp_buffered_end]
        np.set_printoptions(threshold=np.nan)
        bp_means = np.nanmean(bp_param_matrix, axis=0)
        bp_means_list.append(bp_means)
        bp_stddev = np.nanstd(bp_param_matrix, axis=0)
        bp_stderr = stats.sem(bp_param_matrix, axis=0, nan_policy='omit')
        bp_stderr_list.append(bp_stderr)
        print('Base pair averages: {}'.format(bp_means))
        full_param_name = get_full_param_name(str(canal_output_file))

        # Summarize with plotly boxplot.
        plotly_boxplots(base_pair_indices, bp_param_matrix, full_param_name)

        # plot_bp_errorbars(base_pair_indices_list, bp_means_list, bp_stderr_list, input_system_name_list, full_param_name)


with cd("./"):
    # rcParams.update({'figure.autolayout': True})
    # font = {'size': 20}
    # matplotlib.rc('font', **font)
    glob_files = glob.glob('*.ser')
    file_names_list = [str(file_obj) for file_obj in glob_files]
    # levels = np.linspace(0.5, 15, 100)
    # def plot_histogram(flattened_np_vector, bins='fd'):
    while len(file_names_list) > 0:
        example_file = file_names_list[0]
        canal_name = str(example_file)
        # Don't use strip here. I learned my lesson.
        raw_out_name = canal_name[:-4]
        # Find the last '_' in Canal file to get what bp param.
        name_index_start = -1 * raw_out_name[::-1].find('_')
        param_name = raw_out_name[name_index_start:]
        param_file_list = [series for series in file_names_list if param_name in series]
        file_names_list = [series for series in file_names_list if series not in param_file_list]
        input_system_name_list = []
        for file_name in param_file_list:
            end_index = file_name.find(param_name) - 1
            system_name = file_name[:end_index]
            input_system_name_list.append(system_name)
        print('Now visualizing base pair parameter: {}.\n'.format(param_name))
        print('Files being loaded: {}.\n\n'.format('\n'.join(param_file_list)))

        parameter_array_list, base_pair_indices_list, nan_count_list = [], [], []
        bp_means_list, bp_stderr_list = [], []

        summarize_curves(param_file_list, input_system_name_list)

        # flat_parameter_array, base_pair_indices, nan_count = canal_flattener(canal_output_file, param_name)
        # if flat_parameter_array.size == 0:
        #    print("There's an empty file in here...{}\n".format(str(canal_output_file)))
        #    print(flat_parameter_array)
        # else:
        #    parameter_array_list.append(flat_parameter_array)
        #    base_pair_indices_list.append(base_pair_indices)
        #    nan_count_list.append(nan_count)
        #    system_name_list.append(system_name)
        # print(type(parameter_array_list))
        # if type(parameter_array_list) is not tuple:
        #    plt.hist(parameter_array, bins='fd', normed=1,label=system_name_list)
        # else:
        # print(parameter_array_list)
        # canal_with_seaborn(parameter_array_list, param_name, simulation_name_list=system_name_list)
        # simple_heatmap(parameter_array)
        # canal_visualizer(parameter_array_list, param_name, simulation_name_list=system_name_list)
