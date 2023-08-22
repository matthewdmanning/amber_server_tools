# coding: utf-8

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import numpy as np
import numpy.linalg as la


def calculate_gyration_tensor_parameters(points):
    """
    Calculates the gyration tensor parameters R_g^2, η, c, κ from a list of
    all points inside a cavity.
     - R_g^2 is the squared gyration radius
     - η is the asphericity
     - c is the acylindricity
     - κ is the anisotropy
    """

    points = np.array(points, dtype=np.float)
    mean = np.mean(points, axis=0)
    points -= mean
    #print(points)
    gyration_tensor = np.zeros((3, 3))
    for i in range(3):
        for j in range(i, 3):
            gyration_tensor[i, j] = np.dot(points[:, i], points[:, j])
            gyration_tensor[j, i] = gyration_tensor[i, j]
    # cell volume is constant, cavity volume is proportional to len(points)
    gyration_tensor /= len(points)
    eigvals = list(sorted(la.eigvalsh(gyration_tensor), reverse=True))
    return mean, gyration_tensor, eigvals

def calculate_symmetry(eigvals):


    squared_gyration_radius = np.sum(eigvals)
    #print(eigvals)
    #print(squared_gyration_radius)
    #if squared_gyration_radius > 0:
    if True:
        asphericity = (eigvals[:,0] - 0.5 * (eigvals[:,1] + eigvals[:,2])) / squared_gyration_radius
        #print(asphericity)
        acylindricity = (eigvals[:,1] - eigvals[:,2]) / squared_gyration_radius
        anisotropy = (asphericity ** 2 + 0.75 * acylindricity ** 2) ** 0.5
    else:
        asphericity = 0
        acylindricity = 0
        anisotropy = 0
    return squared_gyration_radius, asphericity, acylindricity, anisotropy


# Test code:


def generate_box_points(offset, side_length, n):
    return generate_cuboid_points(offset, (siquyitde_length, side_length, side_length), n)


def generate_cuboid_points(offset, side_lengths, n):
    offset = np.array(offset)
    interval = 0.5 * max(side_lengths) * np.linspace(-1, 1, n)
    points = []
    for x in interval:
        if abs(x) > 0.5 * side_lengths[0]:
            continue
        for y in interval:
            if abs(y) > 0.5 * side_lengths[1]:
                continue
            for z in interval:
                if abs(z) > 0.5 * side_lengths[2]:
                    continue
                points.append((x, y, z) + offset)
    return points


def generate_sphere_points(offset, radius, n):
    offset = np.array(offset)
    interval = radius * np.linspace(-1, 1, n)
    points = []
    for x in interval:
        for y in interval:
            for z in interval:
                if la.norm((x, y, z)) <= radius:
                    points.append((x, y, z) + offset)
    return points


def generate_cylinder_points(offset, radius, length, n):
    offset = np.array(offset)
    interval = max(radius, length / 2) * np.linspace(-1, 1, n)
    points = []
    for x in interval:
        for y in interval:
            for z in interval:
                if abs(z) < length / 2 and la.norm((x, y)) <= radius:
                    points.append((x, y, z) + offset)
    return points


def main():
    #points = np.genfromtxt('/home/mdmannin/mnt/storage/unsat_corona/8A-cluster-60_369C11NH3/eigenvalues.nz.8A-369.md1-6.txt',delimiter=',')
    eigen = np.genfromtxt('/home/mdmannin/mnt/storage/unsat_300K/8A-cluster-60_369C11NH3/eigen.nz.md1-2.dat')

    #eigen = np.genfromtxt('/home/mdmannin/mnt/gpu8/unsat_anneal/18A-120_369C11NH3-80_C12_015M/eigenvalues.nz.md2.dat')
    #eigen = np.genfromtxt('/home/mdmannin/mnt/gpu9/unsat_dna/18A-cluster-120_369C11NH3-80_C12_40dna/eigenvalues.nz.18A-369.md1-4.csv',delimiter=',')
    squared_gyration_radius, asphericity, acylindricity, anisotropy = calculate_symmetry(eigen)
    print('Anisotropy: {}, {}'.format(np.nanmean(anisotropy), np.nanstd(anisotropy)))
    print('Anistropy: Min: {}. Max: {}'.format(np.nanmin(anisotropy), np.nanmax(anisotropy)))
    window = 500
    for index in range(0,10):
        start = 100 * index
        end = start + window
        squared_gyration_radius, asphericity, acylindricity, anisotropy = calculate_symmetry(eigen[start:end,:])
        #print(anisotropy)
        #print('Asphericity: {}'.format(np.mean(asphericity)))
        #print('Acylindricity: {}'.format(np.mean(acylindricity)))
        print('Anisotropy[{}-{}]: {}, {}'.format(start, end, np.mean(asphericity), np.nanstd(asphericity)))

#I think this is a test.
def test():
    silly_offset = (-2, 17.3, 42)
    print('box      (a=1):            ',
          calculate_gyration_tensor_parameters(generate_box_points(silly_offset, 1, 100)))
    print('box      (a=2):            ',
          calculate_gyration_tensor_parameters(generate_box_points(silly_offset, 2, 100)))
    print('cuboid   (a=1, b=2, c=1):  ',
          calculate_gyration_tensor_parameters(generate_cuboid_points(silly_offset, (1, 2, 1), 100)))
    print('cuboid   (a=1, b=20, c=1): ',
          calculate_gyration_tensor_parameters(generate_cuboid_points(silly_offset, (1, 20, 1), 100)))
    print('sphere   (r=1):            ',
          calculate_gyration_tensor_parameters(generate_sphere_points(silly_offset, 1, 100)))
    print('sphere   (r=2):            ',
          calculate_gyration_tensor_parameters(generate_sphere_points(silly_offset, 2, 100)))
    print('cylinder (r=1, l=1):       ',
          calculate_gyration_tensor_parameters(generate_cylinder_points(silly_offset, 1, 1, 100)))
    print('cylinder (r=1, l=20):      ',
          calculate_gyration_tensor_parameters(generate_cylinder_points(silly_offset, 1, 20, 100)))


if __name__ == '__main__':
    main()
