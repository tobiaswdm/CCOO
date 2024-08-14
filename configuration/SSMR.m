% This configuration file starts a time simulation of a SSMR and generates
% the results shown in Fig. 14a in the paper
% T. Weidemann, L. A. Bergman, A. F. Vakakis, M. Krack. (2024)
% "Energy Transfer and Localization in a Forced Cyclic Chain of
% Oscillators with Vibro-Impact Nonlinear Energy Sinks".

simulation = 'TimeSimulation';

%% System parameters
% Tuned system
sys.N_s = 10;               % Number of sectors
sys.kappa_c = 0.05;         % Linear coupling strength
sys.epsilon_a = 0.02;       % Mass ratio of VI-NES
sys.D = 1e-3;               % Uniform Modal Damping Ratio
sys.Gamma_Scale = 0.43;     % Clearance normalized by linear resonance amplitude
sys.eN = 0.8;               % Restitution coefficient

% Mistuned system
sys.sigma_omega = 0;        % Rel. Standard deviation of local eigefrequencies
sys.sigma_g = 0;            % Rel. Standard deviation of local clearances
sys.adjustC = false;        % Set true if sys.D should also refer to
                            % modes of the mistuned system and false if
                            % damping matrix of tuned system should also be
                            % used for the mistuned case

%% Excitation
exc.type = 'harmonic';      % Excitation type 'harmonic' or 'sweep'
exc.k = 2;                  % Excitation wavenumber
exc.harmonic.r = sqrt(1+4*sys.kappa_c*sin(exc.k*pi/10)^2);

% Type of mistuning - 'tuned', 'mistuned_defined' or 'mistuned'
simsetup.TimeSimulation.disorder = 'mistuned';
% Cut transient response in the beginning?
simsetup.TimeSimulation.cut_transient = true;
% Initial conditions - 'random', 'zero' or 'localized'
simsetup.TimeSimulation.initial_conditions = 'zero';