function [qhatmax_practically_stable,qhatmax_stable,qhatmax_unstable, ... 
    qhat_practically_stable,qhat_stable,qhat_unstable,IPR,LF,r] =...
    StabilityAnalysisLSR(c,sys,sol,exc,pattern,disorder,stability,practical_stability)
%STABILITYANALYSIS Study stability along contour plot
%
% c - low level contour estimation
% stability - study asymptotic stability? - true, false
% practical_stability - study practical stability? - true, false

% Determine maximum amplitude allong contour and its kin. accessible ranges
[qhat_max_ana,~,qhat_synchronized,r] = ...
    LocalizedFrequencyAmplitudeCurve(c,sys,exc,pattern,disorder);

% Find beginning of level curves in c
c(2,floor(c(2,:))==c(2,:)) = NaN;

% Amplitudes in reference sector
xi = c(2,2:end);

% Initialize amplitudes
% Maximum
qhatmax_practically_stable = nan(1,length(r));
qhatmax_stable = nan(1,length(r));
qhatmax_unstable = nan(1,length(r));
% Synchronized sector
qhat_practically_stable = nan(1,length(r));
qhat_stable = nan(1,length(r));
qhat_unstable = nan(1,length(r));
% Localization Measures
LF = nan(1,length(r));
IPR = nan(1,length(r));

% Only evaluate final 300 Periods
sol.N_Tau = 300;

parfor (i = 1:length(r), sol.N_Workers)

    % Only consider cases where kinematic constraint is fulfilled
    if ~isnan(qhat_max_ana(i))

        sol_loop = sol;
        exc_loop = exc;
        sys_loop = sys;

        % Initialize excitaiton structure
        exc_loop.harmonic.r = r(i);

        if stability
            
            % Check stability via Slow Flow Analysis
            [stable,qhat] = SlowFlowStability(['LSR_' pattern], ...
                sys_loop, ...
                exc_loop, ...
                xi(i),r(i),disorder);

            if stable
                qhat_stable(i) = qhat(1);
                qhatmax_stable(i) = max(qhat);               
            end

        end


        if practical_stability
            
            % if stability was studied before, only consider
            % asymptotically stable solutions
            
            if (stability && ~isnan(qhat_stable(i))) || ~stability
                % Get initial conditions
                [sol_loop.q0,sol_loop.u0,sol_loop.qa0,sol_loop.ua0] = ...
                    LocalizedInitialConditions(sys_loop,exc_loop,xi(i),r(i),...
                    pattern,disorder,'practical_stability');
    
                % Configure integrator
                sol_loop = ...
                    ConfigureIntegrator(sol_loop,sys_loop,exc_loop,...
                    'no change',false,disorder);
                % Transient of 1000 Periods
                sol_loop.NP_trans = sol_loop.N_P*1000;

                % Simulation
                [ETA,~,~,UA,~] = ...
                    MoreauIntegration(sys_loop,exc_loop,sol_loop,disorder);
                
                % Extract Amplitudes and Significant impacts
                [qhat,~] = ...
                    MeanAmplitude(sys_loop.Phi*ETA(:,2:end),sol_loop.N_Sample);
                N_SIPP = CountImpacts(UA,sol_loop.N_Tau,'average');
                
                switch pattern
                    case 'single'                       
        
                        % Check if solution diverged
                        if N_SIPP(1) >= 1.99 && ... % Sector in 1:1 resonance
                            all(N_SIPP(2:end)<1.99) % No 1:1 remaining secs
                            
                            % Amplitude
                            qhatmax_practically_stable(i) = max(qhat);
                            qhat_practically_stable(i) = qhat(1);
        
                            % Localization measures
                            [IPR(i),LF(i)] = ...
                                LocalizationMeasures(qhat,sys_loop);
        
                            % Set stability back to NaN as practical stability
                            % is the stronger condition
                            qhat_stable(i) = NaN;
                            qhatmax_stable(i) = NaN;
                        end
                    case 'opposing'
                        synchronized_sectors = [1,sys.N_s/2+1];
                        non_synchronized_sectors = 1:sys.N_s;
                        non_synchronized_sectors([1,sys.N_s/2+1]) = [];
        
                        % Check if solution diverged
                        if  ... % Sectors in 1:1 resonance
                            all(N_SIPP(synchronized_sectors) >= 1.99) && ...
                            ... % No 1:1 resonance in remaining secs
                            all(N_SIPP(non_synchronized_sectors)<1.99)
                            
                            % Amplitude
                            qhatmax_practically_stable(i) = max(qhat);
                            qhat_practically_stable(i) = qhat(1);
        
                            % Localization measures
                            [IPR(i),LF(i)] = ...
                                LocalizationMeasures(qhat,sys_loop);
        
                            % Set stability back to NaN as practical stability
                            % is the stronger condition
                            qhat_stable(i) = NaN;
                            qhatmax_stable(i) = NaN;
                        end
                end

            end

        end
        
        % Assign unstable solution
        if isnan(qhat_practically_stable(i)) && ...
                isnan(qhat_stable(i))
            qhatmax_unstable(i) = qhat_max_ana(i);
            qhat_unstable(i) = qhat_synchronized(i);
        end

    end

end

end








