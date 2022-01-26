import copy
import math
import numpy as np

def sphereFit(coords_array):
    #   Assemble the A matrix
    # print(type(coords_array))
    # print(coords_array)
    squares_matrix = np.power(coords_array, 2)
    equation_matrix = np.hstack([squares_matrix, np.ones([np.shape(coords_array)[0], 1])])
    print('Eq matrix:\n {}\n\n'.format(equation_matrix))
    # sum_squares_matrix = np.sum(squares_matrix, axis=1)
    f_matrix = (coords_array[:, 0] * coords_array[:, 0]) + (coords_array[:, 1] * coords_array[:, 1]) + (
        coords_array[:, 2] * coords_array[:, 2])
    print(f_matrix.T)
    #   Assemble the f matrix
    solution, residuals, rank, singular_vals = np.linalg.lstsq(equation_matrix, f_matrix.T)
    C = solution
    print(C)
    #   solve for the radius
    t = (C[0] * C[0]) + (C[1] * C[1]) + (C[2] * C[2]) + C[3]
    radius = math.sqrt(t)
    centers = C[0:3]
    print(radius)
    return radius, centers


def running_mean(x, N):
    cumsum = np.cumsum(np.insert(x, 0, 0))
    return (cumsum[N:] - cumsum[:-N]) / float(N)


def load_CoM_data(com_file):
    # Load coordinates of BP CoM
    # com_file = "distance_com.dat"
    data_matrix = np.loadtxt(com_file)
    frame_vector = data_matrix[1:, 0]
    num_frames = frame_vector.size
    # Get arrays for nucleic COM coords and Au CoM coords
    coords_matrix = data_matrix[1:, 1:]
    absolute_slice = np.mod(np.arange(coords_matrix.shape[-1]), 6)
    print(absolute_slice)
    absolute_coords = coords_matrix[:, absolute_slice < 3]
    origin_coords = coords_matrix[:, absolute_slice >= 3]
    relative_com_vector = absolute_coords - origin_coords

    num_bases = coords_matrix.shape[1] / 6
    # Restack vector such that the third dimension is time/frames, each row is a base_pair, and columns are x,y,z
    com_3d_vector = relative_com_vector.reshape(num_bases, num_frames, 3)
    return com_3d_vector, frame_vector


def load_single_CoM_data(com_file):
    data_matrix = np.loadtxt(com_file)
    frame_vector = data_matrix[1:, 0]
    num_frames = frame_vector.size
    coords_array = data_matrix[1:, 1:]
    relative_com_vector = coords_array[:, 0:3] - coords_array[:, 3:6]
    return relative_com_vector


nucleic_com_file = "basepair_com.dat"
gold_com_file = "au_core_com.dat"

nucleic_3d_vector, frame_vector = load_CoM_data(nucleic_com_file)
gold_3d_vector = load_single_CoM_data(gold_com_file)
distance_3d_vector = nucleic_3d_vector - gold_3d_vector
print(distance_3d_vector)

# Define width of rolling window
window_size = 10
num_frames = nucleic_3d_vector.shape[1]
num_bases = nucleic_3d_vector.shape[0]
num_windows = num_bases - window_size

radius_of_curvature = np.empty([num_windows, num_frames])
for window_index in list(range(num_windows)):
    splice_by_bp = distance_3d_vector[window_index:window_index + window_size + 1, :, :]
    # print('Window splice: {}\n'.format(splice_by_bp.shape))
    for frame_index in list(range(num_frames)):
        frame_splice = splice_by_bp[:, frame_index, :]
        # print('Frame splice: {}\n'.format(frame_splice.shape))
        radius, center_coords = sphereFit(frame_splice)
        radius_of_curvature[window_index, frame_index] = copy.deepcopy(radius)

curvature_file = "curvature.dat"
print(frame_vector.shape, radius_of_curvature.shape)
curvature_matrix = radius_of_curvature
curvature_matrix = np.concatenate([frame_vector.T, radius_of_curvature], axis=0)
np.savetxt(curvature_file, curvature_matrix)
mean_radius = np.mean(radius_of_curvature, axis=1)
rolling_mean_window = 5
rolling_mean_radius = running_mean(mean_radius, rolling_mean_window)
center_of_bending = np.argmin(rolling_mean_radius)
print(center_of_bending - window_size / 2)

# Plot time series of radius of curvature
#radius_trace = []
#for base_pair in list(range(num_bases - window_size - 1)):
#    radius_trace.append(go.Scatter(x=frame_vector, y=radius_of_curvature[base_pair, :]))
#fig = go.Figure(data=radius_trace)
#plotly.offline.plot(fig)
