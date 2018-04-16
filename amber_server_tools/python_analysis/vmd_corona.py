import math

import molecule
import numpy as np
from AtomSel import AtomSel


# Fit the points x to x = ai + b, i=0...N-1, and return a
# a = 12/( (N(N^2 - 1)) ) sum[ (i-(N-1)/2) * xi]

def lsq(x):
    N = len(x)
    xtot = 0
    d = 0.5 * (N - 1)
    for i in range(N):
        xtot += (i - d) * x[i]

        # no need to normalize if all we want is the direction
    #  set xtot [expr $xtot * 12 / ($N * ($N * $N - 1))]
    return xtot


# Given an atom selection and a vector, find the angle with the vector made by
# the best-fit line through the atom coordinates.

def sel_angle(sel, vec):
    # Get the coordinates
    x, y, z = sel.get('x', 'y', 'z')
    xa = lsq(x)
    ya = lsq(y)
    za = lsq(z)

    # Normalize the direction vector for the line
    anorm = math.sqrt(xa * xa + ya * ya + za * za)
    xa /= anorm
    ya /= anorm
    za /= anorm

    # Assume the given vector is normalized!!
    costheta = xa * vec[0] + ya * vec[1] + za * vec[2]

    # Compute acos of the cos and return answer in degrees
    angle = 180 * math.acos(costheta) / 3.14159265

    return angle


# Find the angle between the best fit lines through the two given selections

def calculate_angle(atom_selection1, atom_selection2):
    x1, y1, z1 = np.array(atom_selection1.get('x', 'y', 'z'))
    x2, y2, z2 = np.array(atom_selection2.get('x', 'y', 'z'))

    xa1 = lsq(x1)
    ya1 = lsq(y1)
    za1 = lsq(z1)
    xa2 = lsq(x2)
    ya2 = lsq(y2)
    za2 = lsq(z2)

    anorm1 = math.sqrt(xa1 * xa1 + ya1 * ya1 + za1 * za1)
    anorm2 = math.sqrt(xa2 * xa2 + ya2 * ya2 + za2 * za2)

    xa1 /= anorm1
    ya1 /= anorm1
    za1 /= anorm1

    xa2 /= anorm2
    ya2 /= anorm2
    za2 /= anorm2

    costheta = xa1 * xa2 + ya1 * ya2 + za1 * za2
    angle = 180 * math.acos(costheta) / 3.14159265
    return angle


#################

# Compute the angle for all frames

def sel_angle_frames(mol, seltext, vec):
    sel = AtomSel(seltext, mol)
    n = molecule.numframes(mol)
    return [sel_angle(sel.frame(i), vec) for i in range(n)]


def sel_sel_angle_frames(mol, seltext1, seltext2):
    sel1 = AtomSel(seltext1, mol)
    sel2 = AtomSel(seltext2, mol)
    n = molecule.numframes(mol)
    return [sel_sel_angle(sel1.frame(i), sel2.frame(i)) for i in range(n)]
