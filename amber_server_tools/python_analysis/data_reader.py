import matplotlib.pyplot as plt
import numpy as np

import Molecules

dna_bases = ['DA', 'DC', 'DG', 'DT']
rna_bases = ['A', 'C', 'G', 'U']
dna5_list = ['{}5'.format(base) for base in dna_bases]
dna3_list = ['{}3'.format(base) for base in dna_bases]
rna5_list = ['{}5'.format(base) for base in rna_bases]
rna3_list = ['{}3'.format(base) for base in rna_bases]

def line_gaph(x_data, y_array):
    fig = plt.figure()
    ax = plt.axes()
    ax.plot(data)


batchfilename = 'e2e.md2.dat'
filepath = '/home/mdmannin/Storage/unsat_rna/8A-60_369C11NH3-100rna'
file_name = '/'.joint(filepath, batchfilename)
datafile = open(file_name, 'r')
data_line_list = []
for line in datafile:
    line = line.strip()
    if 'Frame' in line: continue
    data_line_list.append([line.split()])
vector = np.array(data_line_list, dtype=float)


# Returns a list of all residues in the given .prmtop file, including duplicates.
def residue_reader(parm_filename):
    start_string = 'RESIDUE_LABEL'
    end_string = 'RESIDUE_POINTER'
    residue_list = []
    with open(parm_filename) as parm_file:
        for parm_line in parm_file:
            while start_string not in parm_line:
                continue
            line_residues_list = parm_line.split("")
            if len(line_residues_list) == 1 and len(line_residues_list[0]) < 5:
                residue_list.append(line_residues_list)
            elif len(line_residues_list) == 1 and len(line_residues_list[0]) > 4:
                residue_list.extend(line_residues_list[i:i + 4] for i in range(0, len(line_residues_list[0], 4)))
            elif len(line_residues_list) > 1:
                for residue_string in line_residues_list:
                    if len(residue_string) > 4:
                        residue_list.extend(
                            line_residues_list[i:i + r] for i in range(0, len(line_residues_list[0], 4)))
                    elif len(residue_string) <= 4:
                        residue_list.append(residue_string)
    return residue_list


def read_dna_residues(residues_list, res_index):
    strand_length = 1
    strand_seq = [residues_list[res_index]]
    while residues_list[res_index + strand_length] in dna_bases:
        strand_seq.append(residues_list[res_index + strand_length])
        strand_length += 1
    if residues_list[res_index + strand_length + 1] not in dna3_list:
        print("3' DNA base expected. Instead got: {}\n".format(residues_list[res_index + strand_length + 1]))
    else:
        strand_seq.append(residues_list[res_index + strand_length + 1])
        strand_length += 1
    if residues_list[res_index + strand_length + 1] in dna5_list:
        opposite_strand = [residues_list[res_index + strand_length + 1]]
    for bp_index in range(2, strand_length):
        if residues_list[res_index + strand_length + bp_index] in dna_bases:
            opposite_strand.append(residues_list[res_index + strand_length + bp_index])
    if residues_list[res_index + 2 * strand_length] in dna3_list:
        opposite_strand.append(residues_list[res_index + 2 * strand_length])
    else:
        print("End of DNA not a 3' base. Instead got: {}\n".format(residues_list[res_index + 2 * strand_length]))
    new_dna_mole = Molecules.DnaMole()
    new_dna_mole.sequence1 = strand_seq
    new_dna_mole.sequence2 = opposite_strand
    return new_dna_mole


def separate_residues(residues_list, individual_water=False):
    for res_index, residue_name in enumerate(residues_list):
        if residue_name in dna5_list:
            dna_mole = read_dna_residues(residues_list, res_index)


def residue_counter(residues_string, residues_of_interest=[]):
