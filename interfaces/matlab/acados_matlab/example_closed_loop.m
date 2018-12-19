%% example of closed loop simulation



%% handy arguments
compile_mex = 'true';
codgen_model = 'true';
% simulation
sim_method = 'irk';
sim_sens_forw = 'false';
sim_num_stages = 4;
sim_num_steps = 4;
% ocp
ocp_N = 20;
ocp_nlp_solver = 'sqp';
%ocp_nlp_solver = 'sqp_rti';
ocp_qp_solver = 'partial_condensing_hpipm';
%ocp_qp_solver = 'full_condensing_hpipm';
ocp_qp_solver_N_pcond = 5;
%ocp_sim_method = 'erk';
ocp_sim_method = 'erk';
ocp_sim_method_num_stages = 2;
ocp_sim_method_num_steps = 2;



%% setup problem
% linear mass-spring system
model = linear_mass_spring_model;
% dims
T = 10.0; % horizon length time
nx = model.nx; % number of states
nu = model.nu; % number of inputs
nyl = nu+nx; % number of outputs in lagrange term
nym = nx; % number of outputs in mayer term
nbx = nx/2; % number of state bounds
nbu = nu; % number of input bounds
% cost
Vul = zeros(nyl, nu); for ii=1:nu Vul(ii,ii)=1.0; end % input-to-output matrix in lagrange term
Vxl = zeros(nyl, nx); for ii=1:nx Vxl(nu+ii,ii)=1.0; end % state-to-output matrix in lagrange term
Vxm = zeros(nym, nx); for ii=1:nx Vxm(ii,ii)=1.0; end % state-to-output matrix in mayer term
Wl = eye(nyl); for ii=1:nu Wl(ii,ii)=2.0; end % weight matrix in lagrange term
Wm = eye(nym); % weight matrix in mayer term
yrl = zeros(nyl, 1); % output reference in lagrange term
yrm = zeros(nym, 1); % output reference in mayer term
% constraints
x0 = zeros(nx, 1); x0(1)=2.5; x0(2)=2.5;
Jbx = zeros(nbx, nx); for ii=1:nbx Jbx(ii,ii)=1.0; end
lbx = -4*ones(nx, 1);
ubx =  4*ones(nx, 1);
Jbu = zeros(nbu, nu); for ii=1:nbu Jbu(ii,ii)=1.0; end
lbu = -0.5*ones(nu, 1);
ubu =  0.5*ones(nu, 1);



%% acados ocp model
ocp_model = acados_ocp_model();
% dims
ocp_model.set('T', T);
ocp_model.set('nx', nx);
ocp_model.set('nu', nu);
ocp_model.set('nyl', nyl);
ocp_model.set('nym', nym);
ocp_model.set('nbx', nbx);
ocp_model.set('nbu', nbu);
% cost
ocp_model.set('Vul', Vul);
ocp_model.set('Vxl', Vxl);
ocp_model.set('Vxm', Vxm);
ocp_model.set('Wl', Wl);
ocp_model.set('Wm', Wm);
ocp_model.set('yrl', yrl);
ocp_model.set('yrm', yrm);
% dynamics
if (strcmp(ocp_sim_method, 'erk'))
	ocp_model.set('dyn_type', 'expl');
	ocp_model.set('dyn_expr', model.expr_expl);
	ocp_model.set('sym_x', model.sym_x);
	if isfield(model, 'sym_u')
		ocp_model.set('sym_u', model.sym_u);
	end
else % irk
	ocp_model.set('dyn_type', 'impl');
	ocp_model.set('dyn_expr', model.expr_impl);
	ocp_model.set('sym_x', model.sym_x);
	ocp_model.set('sym_xdot', model.sym_xdot);
	if isfield(model, 'sym_u')
		ocp_model.set('sym_u', model.sym_u);
	end
end
% constraints
ocp_model.set('x0', x0);
ocp_model.set('Jbx', Jbx);
ocp_model.set('lbx', lbx);
ocp_model.set('ubx', ubx);
ocp_model.set('Jbu', Jbu);
ocp_model.set('lbu', lbu);
ocp_model.set('ubu', ubu);

ocp_model.model_struct



%% acados ocp opts
ocp_opts = acados_ocp_opts();
ocp_opts.set('compile_mex', compile_mex);
ocp_opts.set('codgen_model', codgen_model);
ocp_opts.set('param_scheme_N', ocp_N);
ocp_opts.set('nlp_solver', ocp_nlp_solver);
ocp_opts.set('qp_solver', ocp_qp_solver);
if (strcmp(ocp_qp_solver, 'partial_condensing_hpipm'))
	ocp_opts.set('qp_solver_N_pcond', ocp_qp_solver_N_pcond);
end
ocp_opts.set('sim_method', ocp_sim_method);
ocp_opts.set('sim_method_num_stages', ocp_sim_method_num_stages);
ocp_opts.set('sim_method_num_steps', ocp_sim_method_num_steps);

ocp_opts.opts_struct



%% acados ocp
% create ocp
ocp = acados_ocp(ocp_model, ocp_opts);
ocp
ocp.C_ocp
ocp.C_ocp_ext_fun




%% acados sim model
sim_model = acados_sim_model();
sim_model.set('T', T/ocp_N);
if (strcmp(sim_method, 'erk'))
	sim_model.set('dyn_type', 'expl');
	sim_model.set('dyn_expr', model.expr_expl);
	sim_model.set('sym_x', model.sym_x);
	if isfield(model, 'sym_u')
		sim_model.set('sym_u', model.sym_u);
	end
	sim_model.set('nx', model.nx);
	sim_model.set('nu', model.nu);
else % irk
	sim_model.set('dyn_type', 'impl');
	sim_model.set('dyn_expr', model.expr_impl);
	sim_model.set('sym_x', model.sym_x);
	sim_model.set('sym_xdot', model.sym_xdot);
	if isfield(model, 'sym_u')
		sim_model.set('sym_u', model.sym_u);
	end
	sim_model.set('nx', model.nx);
	sim_model.set('nu', model.nu);
end

sim_model.model_struct



%% acados sim opts
sim_opts = acados_sim_opts();
sim_opts.set('compile_mex', compile_mex);
sim_opts.set('codgen_model', codgen_model);
sim_opts.set('num_stages', sim_num_stages);
sim_opts.set('num_steps', sim_num_steps);
sim_opts.set('method', sim_method);
sim_opts.set('sens_forw', sim_sens_forw);

sim_opts.opts_struct



%% acados sim
% create sim
sim = acados_sim(sim_model, sim_opts);
sim
sim.C_sim
sim.C_sim_ext_fun



%% closed loop simulation
n_sim = 100;
x_sim = zeros(nx, n_sim+1);
x_sim(:,1) = zeros(nx,1); x_sim(1:2,1) = [3.5; 3.5];
u_sim = zeros(nu, n_sim);

x_traj_init = zeros(nx, ocp_N+1);
u_traj_init = zeros(nu, ocp_N);

tic;

for ii=1:n_sim

	% set x0
	ocp.set('x0', x_sim(:,ii));

	% set trajectory initialization
	ocp.set('x_init', x_traj_init);
	ocp.set('u_init', u_traj_init);

	% solve OCP
	ocp.solve();

	% get solution
	%x_traj = ocp.get('x');
	%u_traj = ocp.get('u');
	u_sim(:,ii) = ocp.get('u', 0);

	% set initial state of sim
	sim.set('x', x_sim(:,ii));
	% set input in sim
	sim.set('u', u_sim(:,ii));

	% simulate state
	sim.solve();

	% get new state
	x_sim(:,ii+1) = sim.get('xn');
end

avg_time_solve = toc/n_sim



% plot result
figure()
subplot(2, 1, 1)
plot(0:n_sim, x_sim);
title('closed loop simulation')
ylabel('x')
subplot(2, 1, 2)
plot(1:n_sim, u_sim);
ylabel('u')
xlabel('sample')



fprintf('\nsuccess!\n\n');



return;
