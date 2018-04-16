import os
import sys
import pickle
import Simulation
import plotly
import IPython.display

sys.path.insert(0, '/home/mdmannin/PycharmProjects/amber_server_tools/python_analysis')
pickling_dir = '/home'

plotly.tools.set_credentials_file(username='mdmannin', api_key='6krwZfpc2JfnWARnNzUb')
plotly.tools.set_config_file(world_readable=True,
                             sharing='public')
def main():
    directory = os.getcwd()
    directory = './'
    current_experiment = Simulation.ExperimentalGroup(parent_dir=directory)
    current_experiment.get_systems_from_dir()
    # print(current_experiment.systems)
    if len(current_experiment.systems) > 0:
        # print(current_experiment)
        current_experiment.find_input_variables()
        current_experiment.print_summary()
    return current_experiment

def plot_sims(exp_group):
    my_dboard = plotly.dashboard_objs.Dashboard()
    my_dboard.get_preview()
    #run_names = set([run.name for run in (sim.md_runs for sim in exp_group.systems)])
    fig = plotly.tools.make_subplots(rows=len(exp_group.systems), cols=1)
    for plotnum, simsys in enumerate(exp_group.systems):
        hbar_data = []
        for mdrun in simsys.md_runs:
            hbar_data.append(plotly.graph_objs.Bar(y=[simsys.system_name], x=[mdrun.nano_length], name=mdrun.name, orientation="h"))
        layout = plotly.graph_objs.Layout(barmode="stack")
        print(hbar_data)
        plot_ind = plotnum + 1
        print(plot_ind)
        print(type(plot_ind))
        fig.append_trace(hbar_data, int(plot_ind), 1)

        #hbar_data = [plotly.graph_objs.Bar(x=[run.name for run in simsys.md_runs], y=[run.nano_length for run in simsys.md_runs], orientation='h')]
        #fig = plotly.graph_objs.Figure(data=hbar_data, layout=layout)
    plotly.plotly.iplot(fig, filename=exp_group.parent_dir)
        #url_1 = plotly.plotly.iplot(hbar_data, filename=simsys.system_name, auto_open=False, layout=layout)
        #plotly.plotly.iplot(hbar_data, filename=simsys.system_name)

#def pickle_sims(exp_group):




if __name__ == "__main__":
    exp_group = main()
    plot_sims(exp_group)