import datetime
import decimal
import glob
import itertools
import os
import re
import sys
# This class contains information about a group of planned or existing AMBER simulations.
# For example, it may contain minimization, heating, equilibration, and production runs.
recurse = True
thermostat_list = ['Berendsen', 'Andersen', 'Langevin']
mdout_pattern = '*md*out'
allout_pattern = '*out'
# traj_pattern = '*.x'
traj_pattern = '*.nc'
rst_pattern = '*.rst7'
prmtop_pattern = '*.prmtop'

common_params = ['dt', 'temp0', 'thermostat', 'gamma_ln', 'taupt', 'ntp', 'pres0', 'taup', 'mcbarint', 'ntr',
                 'restraint_wt', 'restraintmask', 'cut']
important_params = ['imin', 'nmropt', 'ntf', 'ntb', 'igb', 'nsnb', 'ipol', 'gbsa', 'iesp', 'dielc', 'intdiel', 'ibelly',
                    'nstlim', 'nscm', 'nrespa', 'tempi', 'comp', 'ntc', 'tol']
ewald_params = ['ew_type', 'nbflag', 'use_pme', 'vdwmeth', 'eedmeth', 'netfrc', 'NFFT1', 'NFFT2', 'NFFT3', 'Cutoff',
                'Tol', 'Coefficient', 'order']  # (Ewald) Coefficient & Interpolation order

decimal.getcontext().prec = 4


# This class is meant for group different systems, whether replicas or different experimental treatments.
# Allows for comparison of simulation parameters between groups.
def remove_nonfunc_params(param_dict):
    # Delete irrelevant thermostat setttings.
    # if param_dict['thermostat'] != 9 and param_dict['thermostat'] != 10:
    #    del param_dict['nrespa', 'nkija', 'sinrtau', 'idistr']
    # if param_dict['thermostat'] != 1:
    #    del param_dict['tautp']
    # if param_dict['thermostat'] != 2:
    #    del param_dict['vrand']
    # if param_dict['thermostat'] != 3 and param_dict['thermostat'] != 9 and param_dict['thermostat'] != 10:
    #    del param_dict['gamma_ln']
    # Barostat
    # if param_dict['barostat'] != 1 or param_dict['ntp'] == 0:
    #    del param_dict['taup']
    # if param_dict['barostat'] != 2 or param_dict['ntp'] == 0:
    #    del param_dict['mcbarint']
    if param_dict['ntp'] == 0:
        del param_dict['pres0']
    if param_dict['ntr'] == 0 and param_dict['ibelly'] == 0:
        # del param_dict['ntr']
        del param_dict['ibelly']
        del param_dict['restraint_wt']
        del param_dict['restraintmask']
    if param_dict['tempi'] == param_dict['temp0']:
        del param_dict['tempi']
    return param_dict


def check_filepath(file_path, path='./', check_current=True):
    file_dirs = file_path.split("/")[:-1]
    file_name = file_path.split("/")[-1]
    if check_current:
        glob_list = glob.glob(file_name)  # , recursive=True)
        return glob_list
    else:
        # This needs work before it can function. Not a priority.
        path_dirs = path.split("/")
        for directory in file_dirs[::-1]:
            if directory in path_dirs:
                parent_dir = "/".join(path_dirs[:path_dirs.index(directory) + 1])


class ExperimentalGroup():
    def __init__(self, parent_dir=None, systems_list=None, systems_dir_list=None):
        self.parent_dir = parent_dir

        if systems_dir_list:
            self.systems_dir = systems_dir_list
        else:
            self.systems_dir = []
        if systems_list:
            self.systems = systems_list
        else:
            self.systems = []
            self.get_systems_from_dir()
        self.variable_params = []
        self.common_params = {}

    def get_systems_from_dir(self):
        systems_dir_list = []
        if self.parent_dir and not self.systems_dir:
            if self.parent_dir[-1] != "/":
                self.parent_dir += "/"
            if sys.version_info[1] < 5:
                dirs = glob.glob('{}/*/'.format(self.parent_dir))
            elif sys.version_info[1] >= 5:
                dirs = glob.glob('{}/*/'.format(self.parent_dir), recursive=recurse)
            for directory in dirs:
                if glob.glob('{}*.prmtop'.format(directory)):
                    # self.systems_dir.append(directory)
                    systems_dir_list.append(directory)
        self.systems_dir = set(systems_dir_list)
        for directory in self.systems_dir:
            new_system = SimulationSystem(directory=directory)
            if new_system.md_runs and len(new_system.md_runs) > 0:
                self.systems.append(new_system)
        self.systems.sort(key=lambda sim: sim.directory)
        return self.systems

    def find_input_variables(self, md_runs=None, important=True, ewald=True, others=False):
        all_params = []
        params_list = []
        if not md_runs:
            md_runs = []
        for simsys in self.systems:
            for sim in simsys.md_runs:
                md_runs.append(sim)
                for param in sim.params_dict.keys():
                    if param not in all_params:
                        all_params.append(param)
        if self.systems and len(md_runs) > 0:
            first_simulation = md_runs[0]
            # print(first_simulation.params_dict.items())
            for input_variable in first_simulation.params_dict.keys():
                params_list = [sim.params_dict[input_variable] for sim in md_runs if
                               input_variable in sim.params_dict.keys()]
                if len(set(params_list)) > 1:
                    self.variable_params.append(input_variable)
                elif len(set(params_list)) == 1:
                    self.common_params[input_variable] = params_list[0]
                    # if important:
                    #    print('Important params set as different: {}'.format([param for param in params_list if param in important_params]))
                    # if ewald:
                    #    print('Ewald parameters that differ: {}'.format([param for param in params_list if param in ewald_params]))
                    # if others:
                    #    print('Other parameters that differ: {}'.format([param for param in params_list if param not in ewald_params and param not in ewald_params]))

    def print_summary(self):
        for simsys in self.systems:
            simsys.get_common_params()
        # self.common_params = remove_nonfunc_params(self.common_params)
        print('\nExperiment locations: {}'.format(self.parent_dir))
        print('\nContains the following systems...')
        max_string = max([len(sim.system_name) for sim in self.systems])
        for simsys in self.systems:
            padded_name = simsys.system_name + ' ' * (max_string - len(simsys.system_name))
            nano_time = float(simsys.total_time)
            if nano_time - 1. > 0.001:
                print('{0} {1:.3f} ns.'.format(padded_name, nano_time))
            else:
                print('{0} {1:.3f} ps.'.format(padded_name, simsys.total_time))
        print('\nCommon Simulation Parameters...')
        for param_key, value in self.common_params.items():
            if param_key in common_params:
                print('{}: \t\t{}'.format(param_key, value))
        if len(self.variable_params) > 0:
            print('\nThese parameters varied across systems or simulations.')
            for param in self.variable_params:
                print('{}'.format(param))
                for simsys in self.systems:
                    if not hasattr(simsys, 'common_params'):
                        continue
                    if param in simsys.common_params.keys():
                        print('{}: \t{} = \t{}'.format(simsys.system_name, param, simsys.common_params[param]))
                    elif param in simsys.variable_params:
                        print('{}: \t{} = \tVARIABLE'.format(simsys.system_name, param))

        print('\n')
        for simsys in self.systems:
            simsys.print_sims_summary()
            # print('Thermostat: {}\n'.format(self.common_params['thermostat']))


class SimulationSystem():

    def __init__(self, directory=None, parm=None):
        if directory:
            self.directory = directory
        else:
            self.directory = os.getcwd()
        if self.directory[-1] == "/":
            self.directory = self.directory[:-1]
        if parm:
            self.parm_filename = check_filepath(parm)
        else:
            prmtops = self.get_originals('{}/*.prmtop'.format(self.directory))
            if not prmtops or len(prmtops) == 0:
                if sys.version_info[1] < 5:
                    glob.glob('{}/*'.format(self.directory))
                if sys.version_info[1] >= 5:
                    glob.glob('{}/*'.format(self.directory), recursive=recurse)

                self.parm_filename = None
                name = self.directory
                while "/" in name:
                    name = name[name.index('/') + 1:]
            else:
                if isinstance(prmtops, list):
                    self.parm_filename = sorted(prmtops, key=len)[0]
                elif isinstance(prmtops, str):
                    self.parm_filename = prmtops
                name = self.parm_filename[:self.parm_filename.rfind(".")]
                while "/" in name:
                    name = name[name.index('/') + 1:]
        # Scan through all MD output files.
        self.system_name = name
        if sys.version_info[1] < 5:
            self.allout_filenames = [f for f in glob.glob('{}/{}'.format(self.directory, allout_pattern))
                                 if os.path.isfile(f)]
            self.mdout_filenames = [f for f in glob.glob('{}/{}'.format(self.directory, stripdout_pattern)) if
                                    os.path.isfile(f)]
        if sys.version_info[1] >= 5:
            self.allout_filenames = [f for f in
                                     glob.glob('{}/{}'.format(self.directory, allout_pattern), recursive=recurse) if
                                     os.path.isfile(f)]
            self.mdout_filenames = [f for f in
                                    glob.glob('{}/{}'.format(self.directory, mdout_pattern), recursive=recurse)
                                if os.path.isfile(f)]
        self.total_time = 0
        if self.mdout_filenames and len(self.mdout_filenames) > 0:
            self.md_runs = []
            for mdout in self.mdout_filenames:
                new_mdrun = MDRun(mdout_filename=mdout)
                if new_mdrun.wall_clock_start:
                    self.md_runs.append(new_mdrun)
                    self.get_total_time()
                else:
                    continue
        else:
            self.md_runs = []
            print('No MD runs detected for {}'.format(self.system_name))
            return None

        self.md_runs.sort(key=lambda run: run.wall_clock_start)
        self.all_runs = []
        self.all_runs.extend(self.md_runs)
        self.all_runs = self.md_runs
        if self.allout_filenames and len(self.allout_filenames) > 0:
            for outfile in self.allout_filenames:
                if outfile in self.mdout_filenames:
                    continue
                new_run = MDRun(mdout_filename=outfile)
                if new_run.wall_clock_start:
                    self.all_runs.append(new_run)
                    self.get_total_time()
                else:
                    continue
        self.all_runs.sort(key=lambda run: run.wall_clock_start)

        # self.mdin_filenames = self.get_originals('{}/{}'.format(self.directory, mdin_pattern))
        self.trajectories = self.get_originals('{}/{}'.format(self.directory, traj_pattern))
        self.restarts = self.get_originals('{}/{}'.format(self.directory, rst_pattern))
        self.common_params = {}
        self.variable_params = []
        self.get_common_params()

    def get_total_time(self):
        sim_time = 0
        for run in self.md_runs:
            if run.end_nano_time - sim_time > 0.0001:
                sim_time = round(float(run.end_nano_time), 3)
        self.total_time = sim_time
        return sim_time

    def print_sims_summary(self):
        self.md_runs.sort(key=lambda run: run.wall_clock_start)
        print('The following simulations were run for systems: {}'.format(self.system_name))
        last_sim_time = 0
        if not self.md_runs or len(self.md_runs) == 0:
            return False
        max_string = max([len(sim.name) for sim in self.md_runs])
        for sim in self.md_runs:
            padded_name = sim.name + ' ' * (max_string - len(sim.name))
            print('{0} \t{1}\t Simulation length\t{2:.3f} ns'.format(padded_name, sim.wall_clock_start.strftime(
                '%m-%d-%Y %I:%M:%S %p'), sim.nano_length))
        print('Total length of all simulations: {0:.3f} ns'.format(self.total_time))

    def print_summary(self):
        return

    def get_originals(self, glob_pattern, excluded_list=None):
        if not excluded_list:
            excluded_list = ['strip.', 'ions.']
        if sys.version_info[1] < 5:
            full_list = glob.glob(glob_pattern)
        elif sys.version_info[1] >= 5:
            full_list = glob.glob(glob_pattern, recursive=recurse)
        filtered_list = [filename for filename in full_list if
                         any(excluded not in filename for excluded in excluded_list)]
        if len(filtered_list) == 0:
            filtered_list = full_list
        return [mdrun for mdrun in filtered_list if check_filepath(mdrun)]

    def get_common_params(self):
        all_params = {}
        if not self.md_runs:
            print('No MD runs found for {}'.format(self.directory))
            return False
        for md_run in self.md_runs:
            for param, value in md_run.params_dict.items():
                if param not in all_params.keys():
                    all_params[param] = value
                elif value != all_params[param]:
                    self.variable_params.append(param)
        for param, value in all_params.items():
            if param not in self.variable_params:
                self.common_params[param] = value
        for md_run in self.md_runs:
            excess_params = [param for param in all_params if param not in md_run.params_dict.keys()]
            for param in excess_params:
                if param not in self.variable_params:
                    self.variable_params.append(param)
                if param in self.common_params.keys():
                    del self.common_params[param]


class MDRun():
    def __init__(self, mdout_filename=None, parm_filename=None, input_rst_filename=None, output_rst_filename=None,
                 trajectory_filename=None, ref_filename=None):
        self.mdout_filename = mdout_filename
        self.name = self.mdout_filename[::-1][:self.mdout_filename[::-1].index('/')][::-1]  # Ugly, but I'm not sorry.
        self.wall_clock_start = None
        self.start_nano_time = 0
        self.end_nano_time = 0
        self.nano_length = 0
        self.parm_filename = parm_filename
        self.input_rst_filename = input_rst_filename
        self.output_rst_filename = output_rst_filename
        self.trajectory_filename = trajectory_filename
        self.ref_filename = ref_filename
        self.last_updated = os.stat(mdout_filename).st_mtime
        self.thermostat = None
        self.params_dict = {}
        self.last_time = 0
        if self.mdout_filename:
            self.get_sim_params()
        if len(self.params_dict.keys()) == 0:
            return None
        self.get_times()

    def get_times(self):
        self.last_time = self.get_output_value("TIME(PS)", last_n_lines=100)
        self.end_nano_time = round(float(self.last_time) / 1000., 3)
        self.nano_length = self.end_nano_time - self.start_nano_time
        # self.last_time.quantize(decimal.Decimal(10) ** -2)
        if self.nano_length < 0:
            print('Got negative value for simulation length of {} for {}.'.format(self.nano_length, self.name))
            self.nano_length = 0


    def get_sim_params(self):
        # Get Simulation parameters.
        with open(self.mdout_filename, 'r') as mdout_file:
            for line in mdout_file:
                if 'implementation' and 'Release' in line:
                    self.params_dict['Amber Version'] = line[2:]
                elif 'Run on' in line:
                    for word in line.split():
                        if '/' in word:
                            date_string = word
                        elif ':' in word:
                            time_string = word
                    runtime_string = '{} {}'.format(date_string, time_string)
                    self.wall_clock_start = datetime.datetime.strptime(runtime_string, '%m/%d/%Y %H:%M:%S')
                if 'File Assignments' in line:
                    for line_num in list(range(12)):
                        line = next(mdout_file).split()
                        for index, word in enumerate(line):
                            if "INPCRD" in word:
                                self.input_rst_filename = check_filepath(line[index + 1])
                            elif "PARM" in word:
                                self.parm_filename = check_filepath(line[index + 1])
                            elif "RESTRT" in word:
                                self.output_rst_filename = check_filepath(line[index + 1])
                            elif "REFC" in word:
                                self.ref_filename = check_filepath(line[index + 1])
                            elif "MDCRD" in word:
                                self.trajectory_filename = check_filepath(line[index + 1])
                if 'General flags' in line:
                    params_lines = list(itertools.islice(mdout_file, 80))
                    params_block = []
                    for param_line in params_lines:
                        if 'Mask' in param_line:
                            mask = param_line.split()[1]
                            self.params_dict['restraintmask'] = mask
                        if 'begin time read' in param_line:
                            start_time = param_line.split()[param_line.split().index('ps') - 1]
                            if start_time[0] == "=":
                                start_time = start_time[1::]
                            self.start_nano_time = round(float(start_time) / 1000., 3)
                            break
                        params_block.append(param_line)
                    filename_list = re.split(',|\n', ''.join(params_block))
                    for method in thermostat_list:
                        if method in params_block:
                            self.thermostat = method
                            self.params_dict['thermostat'] = method
                    params_list = [phrase for phrase in filename_list if "=" in phrase]
                    for phrase in params_list:
                        pair = list(filter(None, re.split('\s|=', phrase)))
                        if len(pair) == 2:
                            param_name, param_value = list(filter(None, re.split('\s|=', phrase)))
                            self.params_dict[param_name] = param_value
                    # grep_command = '''grep -A 80 "General flags" {}'''.format(self.mdout_filename)
                    # grep_out = subprocess.Popen(grep_command, shell=True, stdout=subprocess.PIPE).stdout
                    # params_block = grep_out.read()
                    # Split grep output by newlines and commas. This will give strings containing 'params = value'

    def get_output_value(self, search_string, search_block=None, first_value=False, last_n_lines=None):
        # Grab value from MD out, such as time, temp, pressure, etc.
        for line in reversed(list(open(self.mdout_filename))):
            if search_string in line:
                for index, word in enumerate(line):
                    if search_string in word or word in search_string:
                        return line.split()[index + 3]

        return False
