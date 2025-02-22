%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CC (pronounced Sisi) is a tool that performs numerical and/or
% analytical analyses on a Cylic Chain of Oscialltors with Vibro-Impact
% Nonlinear Energy Sinks (VI-NESs)
%
% The Code for CC was written by:
% Tobias Weidemann - (C) 2024
% University of Stuttgart, Germany
% Institute of Aircraft Propulsion Systems
%
% Contact: tobias.weidemann@ila.uni-stuttgart.de
%
% Feel free to use, share and modify under the GPL-3.0 license.
% CC is purely academic and comes with no warranty.
% If you use CC for your own research, please refer to the paper:
%
% T. Weidemann, L. A. Bergman, A. F. Vakakis, M. Krack. (2024)
% "Energy Transfer and Localization in a Forced Cyclic Chain of
% Oscillators with Vibro-Impact Nonlinear Energy Sinks".
% Manuscript submitted to Nonlinear Dynamics
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ETA0,CHI0,QA0,UA0] = LocalizedInitialConditions(sys,exc,xi,r, ...
    pattern,disorder,stability)
%LOCALIZEDINITIALCONDITIONS Return initial conditions of HB solution
%
% xi -scalar clearance normalized amplitude
% r - scalar excitation frequency
% pattern - 'single' or 'opposing'

[Q,theta,expDelta] = RecoverCondensedDOFs(sys,exc,r,xi,pattern,disorder);

% expDelta = exp(-1i*Delta) -> negative sign
Delta = -angle(expDelta);

% Get modal initital conditions
% Recall that inv(Phi)=transpose(Phi) for tuned system modes
ETA0 = transpose(sys.Phi) * Q;
CHI0 = real(1i*r.*ETA0);
ETA0 = real(ETA0);

% Get initial displacement of absorbers

QA0 = zeros(sys.N_s,length(r)); % Displacement
UA0 = zeros(sys.N_s,length(r)); % Velocity


switch disorder
    case 'tuned'
        qahat = sys.Gamma(1)*theta;
    case 'mistuned'
        qahat = sys.Gamma_mt(1)*theta;
    otherwise
        error('Case not defined.')
end

% Triangle Wave motion
QA0(1,:) = 2*qahat*asin(cos(angle(Q(1,:))-Delta))/pi;

% Velocity magnitude
qadot = 2*r.*qahat/pi;

index = 0<=wrapToPi(angle(Q(1,:))-Delta) & ...
    wrapToPi(angle(Q(1,:))-Delta)<=pi;

% Assign velocities
UA0(1,index) = -qadot;
UA0(1,~index) = qadot;

% repeeat for possible opposing sector
if strcmp(pattern,'opposing')
    QA0(sys.N_s/2+1,:) = 2*qahat*asin(cos(angle(Q(sys.N_s/2+1,:))-Delta))/pi;

    index = 0<=wrapToPi(angle(Q(sys.N_s/2+1,:))-Delta) & ...
    wrapToPi(angle(Q(sys.N_s/2+1,:))-Delta)<pi;

    % Assign velocities
    UA0(sys.N_s/2+1,index) = -qadot;
    UA0(sys.N_s/2+1,~index) = qadot;
end

if strcmp(stability,'practical_stability')
    switch pattern
        case 'single'

            % Assign same initial velocity as oscillator
            % in non localized sector
            UA0(2:end,:) = sys.Phi(2:end,:)*CHI0;
        
            % Place absorber at cavity wall
            switch disorder
                case 'tuned'
                    QA0(2:end,:) = sys.Gamma(3:2:end) + ...
                        sys.Phi(2:end,:)*ETA0;
                case 'mistuned'
                    QA0(2:end,:) = sys.Gamma_mt(3:2:end) + ...
                        sys.Phi(2:end,:)*ETA0;
            end

        case 'opposing'
            % Non-synchronized sectors
            non_synchronzized = true(1,sys.N_s);
            non_synchronzized([1,sys.N_s/2 + 1]) = false;
          
            % Assign same initial velocity as oscillator
            % in non localized sector
            UA0(non_synchronzized,:) = sys.Phi(non_synchronzized,:)*...
                                           CHI0;

            if rem(exc.k,2)~=0
                QA0(non_synchronzized,:) = sys.Gamma_Scale*sys.qref + ...
                                           sys.Phi(non_synchronzized,:) ...
                                            *ETA0;
            else
                QA0(2:(sys.N_s/2),:) = ...
                    sys.Gamma_Scale*sys.qref + ...
                    sys.Phi(2:(sys.N_s/2),:)*ETA0;
                QA0((sys.N_s/2 +1):sys.N_s,:) = ...
                    -sys.Gamma_Scale*sys.qref + ...
                    sys.Phi((sys.N_s/2 +1):sys.N_s,:)*ETA0;
            end


    end
end


end



