#
# Copyright (c) The acados authors.
#
# This file is part of acados.
#
# The 2-Clause BSD License
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.;
#

# reference : "Towards Time-optimal Tunnel-following for Quadrotors", Jon Arrizabalaga et al.

import numpy as np
from time import time
import casadi as ca
import os
from common import *
from acados_settings import AcadosCustomOcp
from matplotlib import pyplot
from visualize_mpl import animOptVars

def plan_ocp( ocp_wrapper):
    '''Motion control problem of drone trajectory tracking'''

    # dimensions
    nx = ocp_wrapper.nx
    nu = ocp_wrapper.nu
    ns = ocp_wrapper.ns

    # initialize iteration variables
    t0 = 0
    discr_step = np.array([])
    times = np.array([[0]])
    mpc_iter = 0
    cost = 0
    fail = 0

    # Define states, controls, and slacks as coloumn vectors
    zeta_0 = np.copy(ocp_wrapper.zeta_0)
    u_0 = np.copy(U_REF)

    # ns x 2 (lower and upper bound))
    Sl_0 = np.zeros((ns, 2))

    # Convert 1D array (nx,) to 3D (nx, 1, N+1)
    zeta_N = ca.repmat(np.reshape(zeta_0, (nx,1)), 1, N+1)

    # nx x N+1 x mpc_iter (to plot state during entire Horizon)
    state_traj = ca.repmat(zeta_0, 1, N+1)
    # nu x mpc_iter
    control_traj = ca.repmat(u_0, 1, 1)
    # 3 x mpc_iter (iteration time, cost)
    sample_traj = ca.repmat(np.array([0, 0]).T, 1)

    # Control loop entry point

    for i in range(Nsim):
        # Store previous iterate data for plots
        discr_step = ca.reshape(np.array([t0, cost]), 2, 1)
        sample_traj = np.concatenate( (sample_traj, discr_step), axis = 1)
        state_traj = np.dstack((state_traj, ocp_wrapper.zeta_N))
        control_traj = np.concatenate((control_traj,
                                        np.reshape(ocp_wrapper.u_N[:, 0], (nu, 1))),
                                        axis = 1)
        t1 = time()

        end = ocp_wrapper.cost_update_ref(zeta_N[:, 0], U_HOV)
        if (end or fail >10) :
            print("MPC exit !")
            break

        # Solve the OCP with updated state and controls
        status =  ocp_wrapper.solve_and_sim()
        if(status !=0):
            fail = fail + 1
            print("Optima not found")

        # cost = ocp_wrapper.get_cost()

        t0 = round(t0 + T_del, 3)
        t2 = time()
        ocp_soln_time = t2-t1
        times = np.vstack(( times, ocp_soln_time))
        mpc_iter = mpc_iter + 1

        zeta_N = ocp_wrapper.zeta_N

        print(f'\n Soln. {mpc_iter} Sim: {(np.round(ocp_wrapper.zeta_N[:, 0],2).T)} at {round(t0,2)} s\t')

    sqp_max_sec = round(np.array(times).max(), 3)
    sqp_avg_sec = round(np.array(times).mean(), 3)
    avg_n = round(np.abs(state_traj[1, 0, :]).mean(), 4)
    avg_b = round(np.abs(state_traj[2, 0, :]).mean(), 4)
    print(f'\nNumber of NLP failures {fail}')
    print(f'Max. solver time\t: {sqp_max_sec * 1000} ms')
    print(f'Avg. solver time\t: {sqp_avg_sec * 1000} ms')
    print(f'Avg. n\t\t: {avg_n} m')
    print(f'Avg. b\t\t: {avg_b} m')
    # print(f'Avg. lateral deviation N\t: {lat_devN} m')


    return sample_traj, state_traj, control_traj

if __name__ == '__main__':

    custom_ocp = AcadosCustomOcp()
    custom_ocp.setup_acados_ocp()
    traj_sample, traj_ST, traj_U = plan_ocp(custom_ocp)
    animOptVars(traj_sample, traj_ST, traj_U)
    # plotOptVars(traj_sample[0, :], traj_ST[:, 0, :], traj_U)