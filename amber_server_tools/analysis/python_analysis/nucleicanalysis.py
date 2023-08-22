'''
Structure and To-do List

Class: Topology (scrapes and stores information for system parmeter topology file)
Functions
    -Residue identifier - capable of distinguishing DNA, RNA, protein, and other
    -Water and salt counter
    -Force field

bash_analysis Functions - interfaces with PyTraj
-e2e
-rog
-rmsd, rmsf, symmrmsd, rmsavgcorr, etc.
-Vector functions: calculate vectors, distances, and angles between specified atoms
*Includes support for calculating intra-residue quantities only.

%FLAG TITLE
%FLAG POINTERS
%FLAG ATOM_NAME
%FLAG CHARGE
%FLAG ATOMIC_NUMBER
%FLAG MASS
%FLAG ATOM_TYPE_INDEX
%FLAG NUMBER_EXCLUDED_ATOMS
%FLAG NONBONDED_PARM_INDEX
%FLAG RESIDUE_LABEL
%FLAG RESIDUE_POINTER
%FLAG BOND_FORCE_CONSTANT
%FLAG BOND_EQUIL_VALUE
%FLAG ANGLE_FORCE_CONSTANT
%FLAG ANGLE_EQUIL_VALUE
%FLAG DIHEDRAL_FORCE_CONSTANT
%FLAG DIHEDRAL_PERIODICITY
%FLAG DIHEDRAL_PHASE
%FLAG SCEE_SCALE_FACTOR
%FLAG SCNB_SCALE_FACTOR
%FLAG SOLTY
%FLAG LENNARD_JONES_ACOEF
%FLAG LENNARD_JONES_BCOEF
%FLAG BONDS_INC_HYDROGEN
%FLAG BONDS_WITHOUT_HYDROGEN
%FLAG ANGLES_INC_HYDROGEN
%FLAG ANGLES_WITHOUT_HYDROGEN
%FLAG DIHEDRALS_INC_HYDROGEN
%FLAG DIHEDRALS_WITHOUT_HYDROGEN
%FLAG EXCLUDED_ATOMS_LIST
%FLAG HBOND_ACOEF
%FLAG HBOND_BCOEF
%FLAG HBCUT
%FLAG AMBER_ATOM_TYPE
%FLAG TREE_CHAIN_CLASSIFICATION
%FLAG JOIN_ARRAY
%FLAG IROTAT
%FLAG SOLVENT_POINTERS
%FLAG ATOMS_PER_MOLECULE
%FLAG BOX_DIMENSIONS
%FLAG RADIUS_SET
%FLAG RADII
%FLAG SCREEN
%FLAG IPOLl

Pointers
NATOM (number of atoms in system)................= 255066
NTYPES (number of atom type names)...............= 26
NBONH (number of bonds containing H).............= 251867
MBONA (number of bonds without H)................= 3038
NTHETH (number of angles containing H)...........= 5456
MTHETA (number of angles without H)..............= 6187
NPHIH (number of dihedrals containing H).........= 9556
MPHIA (number of dihedrals without H)............= 21042
NHPARM (currently unused)........................= 0
NPARM (1 if made with addles, 0 if not)..........= 0
NNB (number of excluded atoms)...................= 364418
NRES (number of residues in system)..............= 83984
NBONA (MBONA + constraint bonds).................= 3038
NTHETA (MTHETA + constraint angles)..............= 6187
NPHIA (MPHIA + constraint dihedrals).............= 21042
NUMBND (number of unique bond types).............= 64
NUMANG (number of unique angle types)............= 124
NPTRA (number of unique dihedral types)..........= 81
NATYP (number of nonbonded atom types)...........= 43
NPHB (number of distinct 10-12 H-bond pairs).....= 1
IFPERT (1 if prmtop is perturbed; not used)......= 0
NBPER (perturbed bonds; not used)................= 0
NGPER (perturbed angles; not used)...............= 0
NDPER (perturbed dihedrals; not used)............= 0
MBPER (bonds in perturbed group; not used).......= 0
MGPER (angles in perturbed group; not used)......= 0
MDPER (diheds in perturbed group; not used)......= 0
IFBOX (Type of box: 1=orthogonal, 2=not, 0=none).= 1
NMXRS (number of atoms in largest residue).......= 135
IFCAP (1 if solvent cap exists)..................= 0
NUMEXTRA (number of extra points in topology)....= 0

SOLVENT POINTERS

IPTRES (Final solute residue)....................= 791
NSPM (Total number of molecules).................= 83846
NSPSOL (The first solvent "molecule")............= 654

'''

class Topology:

    def __init__(self, filename, system=None):
        self.filename = filename
        self.system = system
        self.residue_type_dict = {}
        self.nucleic_res_dict = {}
        self.protein_res_dict = {}

    def extract_info(self):

        return

    def extract_residues(self):
        return


