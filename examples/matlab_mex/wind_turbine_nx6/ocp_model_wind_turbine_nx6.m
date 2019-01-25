function model = wind_turbine_nx6p2_model()

import casadi.*

%% define the symbolic variables of the plant
ocp_S02_DefACADOSVarSpace;

%% load plant parameters
ocp_S03_SetupSysParameters;

%% Define casadi spline functions
% aerodynamic torque coefficient for FAST 5MW reference turbine
load('CmDataSpline.mat')
c_StVek = c_St';
splineCMBL = interpolant('Spline','bspline',{y_St,x_St},c_StVek(:));
clear x_St y_St c_St c_StVek

%% define ode rhs in explicit form (22 equations)
ocp_S04_SetupNonlinearStateSpaceDynamics;

%% generate casadi C functions
nx = 8;
nu = 2;
np = 1;

%% populate structure
model.nx = nx;
model.nu = nu;
model.np = np;
model.sym_x = x;
model.sym_xdot = dx;
model.sym_u = u;
model.sym_p = p;
model.expr_f_expl = fe;
model.expr_f_impl = fi;
%model.expr_h = h;
%model.expr_h_e = hN;
%model.expr_y = expr_y;
%model.expr_y_e = expr_y_e;

