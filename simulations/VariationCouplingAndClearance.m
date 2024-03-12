%% Initialize variables

% Actual amplitudes

% Tuned system
qhat_tuned = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c, ...
                simsetup.VariationCouplingAndClearance.Number_GammaScale);
qhat_tuned_std = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c, ...
                simsetup.VariationCouplingAndClearance.Number_GammaScale);
qhat_min_tuned = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c);
Gamma_Scale_min_tuned = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c);

% Fixed absorber
qhat_fixed = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c, ...
                simsetup.VariationCouplingAndClearance.Number_GammaScale);
qhat_fixed_std = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c, ...
                simsetup.VariationCouplingAndClearance.Number_GammaScale);
qhat_min_fixed = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c);
Gamma_Scale_min_fixed = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c);

% Removed absorber
qhat_removed = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c, ...
                    simsetup.VariationCouplingAndClearance.Number_GammaScale);
qhat_removed_std = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c, ...
                    simsetup.VariationCouplingAndClearance.Number_GammaScale);
qhat_min_removed = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c);
Gamma_Scale_min_removed = zeros(simsetup.VariationCouplingAndClearance.Number_kappa_c);

% Determine couplings strengts
switch simsetup.VariationCouplingAndClearance.Scaling_kappa_c
    case 'logarithmic'
        kappa_c = logspace(log10(simsetup.VariationCouplingAndClearance.Range_kappa_c(1)),...
                           log10(simsetup.VariationCouplingAndClearance.Range_kappa_c(2)),...
                           simsetup.VariationCouplingAndClearance.Number_kappa_c);
    case 'linear'
        kappa_c = linspace(simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
                           simsetup.VariationCouplingAndClearance.Range_kappa_c(2),...
                           simsetup.VariationCouplingAndClearance.Number_kappa_c);
    otherwise
        error('Case not defined.')
end

% Determine normalized clearances
switch simsetup.VariationCouplingAndClearance.Scaling_GammaScale
    case 'logarithmic'
        Gamma_Scale = logspace(log10(simsetup.VariationCouplingAndClearance.Range_GammaScale(1)),...
                           log10(simsetup.VariationCouplingAndClearance.Range_GammaScale(2)),...
                           simsetup.VariationCouplingAndClearance.Number_GammaScale);
    case 'linear'
        Gamma_Scale = linspace(simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
                           simsetup.VariationCouplingAndClearance.Range_GammaScale(2),...
                           simsetup.VariationCouplingAndClearance.Number_GammaScale);
    otherwise
        error('Case not defined.')
end



%% Vary nominal parameters

for i = 1:simsetup.VariationCouplingAndClearance.Number_kappa_c
    disp(['Coupling strength ' num2str(i) ' of ' ...
        num2str(simsetup.VariationCouplingAndClearance.Number_kappa_c)])

    % Set coupling strength
    sys.kappa_c = kappa_c(i);
    sys.Gamma_Scale = 0;
    
    
    parfor j = 1:simsetup.VariationCouplingAndClearance.Number_GammaScale
        disp(['Clearance ' num2str(j) ' of ' ...
        num2str(simsetup.VariationCouplingAndClearance.Number_GammaScale)])
        
        % Give system parameters
        sys_loop = sys;

        % Set nominal clearance
        sys_loop.Gamma_Scale = Gamma_Scale(j);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Build nominal system
        [sys_loop,exc_loop] = BuildSystem(sys_loop,exc,'tuned');
        
        % Determine performance of tuned system with absorber
    
        % Frequency range for stepping
        r_range = [sys_loop.r_k(exc_loop.k+1), sys_loop.r_k_noabs(exc_loop.k+1)];
        r_range = simsetup.VariationCouplingAndClearance.r_scale.*r_range;
        r_steps = linspace(r_range(1),r_range(2),...
                           simsetup.VariationCouplingAndClearance.N_rSteps);
        
        % Resonance amplitude
        [qhat_tuned(i,j), qhat_tuned_std(i,j), ~] = ....
        FindResonance(sys_loop,sol,exc_loop,r_steps,'tuned');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Build mistuned system removed absorber
        sys_loop.absorber_malfunction = 'removed';
        [sys_mt,exc_mt] = BuildSystem(sys_loop,exc_loop,'mistuned');
        
        % Determine resonance response level in linear case with fixed
        % absorbers
        r_lin = linspace(0.99*sys_mt.r_k_mt(1),...
                         1.01*sys_mt.r_k_mt(end),3000);
        q = max(abs(ComputeLinearResponse(r_lin,sys_mt,exc_mt,...
                                    'mistuned','fixed_absorbers')),[],1);
        % Extract overall maximum and corresponding frequency
        [~,i_max] = max(q,[],2);
        r_range = r_lin(i_max);
        
        % Determine resonance response level in linear case with removed
        % absorbers
        r_lin = linspace(0.99*sys_mt.r_k_noabs_mt(1),...
                               1.01*sys_mt.r_k_noabs_mt(end),3000);
        q = max(abs(ComputeLinearResponse(r_lin,sys_mt,exc_mt,...
                                    'mistuned','removed_absorbers')),[],1);

        % Extract overall maximum and corresponding frequency
        [~,i_max] = max(q,[],2);
        r_range = horzcat(r_range,r_lin(i_max));
        
        % Scale frequency range for stepping
        r_range = simsetup.VariationCouplingAndClearance.r_scale.*r_range;
        r_steps = linspace(r_range(1),r_range(2),...
                   simsetup.VariationCouplingAndClearance.N_rSteps);


        % Resonance amplitude
        [qhat_removed(i,j), qhat_removed_std(i,j), nsipp] = ....
        FindResonance(sys_mt,sol,exc_mt,r_steps,'mistuned');

        if nsipp(1) ~= 0
            warning('Impact detected in sector without absorber.')
        end
 

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Build mistuned system fixed absorber
        sys_loop.absorber_malfunction = 'fixed';
        [sys_mt,exc_mt] = BuildSystem(sys_loop,exc_loop,'mistuned');

        
        % Determine resonance response level in linear case with fixed
        % absorbers
        r_lin = linspace(0.99*sys_mt.r_k_mt(1),...
                               1.01*sys_mt.r_k_mt(end),3000);
        q = max(abs(ComputeLinearResponse(r_lin,sys_mt,exc_mt,...
                                    'mistuned','fixed_absorbers')),[],1);
        % Extract overall maximum and corresponding frequency
        [~,i_max] = max(q,[],2);
        r_range = r_lin(i_max);
        
        % Determine resonance response level in linear case with removed
        % absorbers
        r_lin = linspace(0.99*sys_mt.r_k_noabs_mt(1),...
                               1.01*sys_mt.r_k_noabs_mt(end),3000);
        q = max(abs(ComputeLinearResponse(r_lin,sys_mt,exc_mt,...
                                    'mistuned','removed_absorbers')),[],1);

        % Extract overall maximum and corresponding frequency
        [~,i_max] = max(q,[],2);
        r_range = horzcat(r_range,r_lin(i_max));
        
        % Scale frequency range for stepping
        r_range = simsetup.VariationCouplingAndClearance.r_scale.*r_range;
        r_steps = linspace(r_range(1),r_range(2),...
                   simsetup.VariationCouplingAndClearance.N_rSteps);

        % Resonance amplitude
        [qhat_fixed(i,j), qhat_fixed_std(i,j), nsipp] = ....
        FindResonance(sys_mt,sol,exc_mt,r_steps,'mistuned');

        if nsipp(1) ~= 0
            warning('Impact detected in sector without absorber.')
        end
        
    end
  
    
    % Build nominal system to determine linear resonance amplitude
    sys.Gamma_Scale = 0;
    [sys,exc] = BuildSystem(sys,exc,'tuned');
    qhat_tuned(i,:) = qhat_tuned(i,:)/sys.qref;
    qhat_tuned_std(i,:) = qhat_tuned_std(i,:)/sys.qref;
    qhat_removed(i,:) = qhat_removed(i,:)/sys.qref;
    qhat_removed_std(i,:) = qhat_removed_std(i,:)/sys.qref;
    qhat_fixed(i,:) = qhat_fixed(i,:)/sys.qref;
    qhat_fixed_std(i,:) = qhat_fixed_std(i,:)/sys.qref;

    [qhat_min_tuned(i),ii] = min(qhat_tuned(i,:));
    Gamma_Scale_min_tuned(i) = Gamma_Scale(ii);
    [qhat_min_removed(i),ii] = min(qhat_removed(i,:));
    Gamma_Scale_min_removed(i) = Gamma_Scale(ii);
    [qhat_min_fixed(i),ii] = min(qhat_fixed(i,:));
    Gamma_Scale_min_fixed(i) = Gamma_Scale(ii);

end

% Save data
save([savepath 'qhat_tuned.mat'],'qhat_tuned')
save([savepath 'qhat_std.mat'],'qhat_tuned_std')
save([savepath 'qhat_removed.mat'],'qhat_removed')
save([savepath 'qhat_removed_std.mat'],'qhat_removed_std')
save([savepath 'qhat_fixed.mat'],'qhat_fixed')
save([savepath 'qhat_fixed_std.mat'],'qhat_fixed_std')


if (simsetup.VariationCouplingAndClearance.Number_GammaScale>1 && ...
    simsetup.VariationCouplingAndClearance.Number_kappa_c>1)

    [XX,YY] = meshgrid(Gamma_Scale,kappa_c);

    % Tuned system
    figure(1);
    surf(XX,YY,qhat_tuned,'EdgeAlpha',0)
    hold on;
    plot3(Gamma_Scale_min_tuned,kappa_c,qhat_min_tuned,...
        'LineWidth',3,'Color',color.show)
    title('Tuned system')
    box on;
    colormap(1-pink)
    xlabel('$\Gamma/\hat{q}_\mathrm{ref}$')
    ylabel('$\kappa_\mathrm{c}$')
    zlabel('$\hat{q}/\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    set(gca,'YScale','log')
    xlim([simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
         simsetup.VariationCouplingAndClearance.Range_GammaScale(2)])
    ylim([simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
         simsetup.VariationCouplingAndClearance.Range_kappa_c(2)])
    zlim([-inf inf])
    savefig([savepath 'qhat_tuned.fig'])
    
    % Fixed absorber
    figure(2);
    surf(XX,YY,qhat_fixed,'EdgeAlpha',0)
    hold on;
    plot3(Gamma_Scale_min_fixed,kappa_c,qhat_min_fixed,...
        'LineWidth',3,'Color',color.show)
    plot3(simsetup.VariationCouplingAndClearance.Range_GammaScale,...
        simsetup.VariationCouplingAndClearance.Range_kappa_c(1)*[1 1],...
        [1 1],'--k','LineWidth',1.5)
    title('Fixed absorber')
    box on;
    colormap(1-pink)
    xlabel('$\Gamma/\hat{q}_\mathrm{ref}$')
    ylabel('$\kappa_\mathrm{c}$')
    zlabel('$\hat{q}^\ast /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    set(gca,'YScale','log')
    xlim([simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
         simsetup.VariationCouplingAndClearance.Range_GammaScale(2)])
    ylim([simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
         simsetup.VariationCouplingAndClearance.Range_kappa_c(2)])
    zlim([-inf inf])
    savefig([savepath 'qhat_fixed.fig'])
    
    % removed absorber
    figure(3);
    surf(XX,YY,qhat_removed,'EdgeAlpha',0)
    hold on;
    plot3(Gamma_Scale_min_removed,kappa_c,qhat_min_removed,...
        'LineWidth',3,'Color',color.show)
    plot3(simsetup.VariationCouplingAndClearance.Range_GammaScale,...
        simsetup.VariationCouplingAndClearance.Range_kappa_c(1)*[1 1],...
        [sys.qref sys.qref]*(2*sys.D/sqrt(1-sys.epsilon_a)),...
        '--k','LineWidth',1.5)
    title('Removed absorber')
    box on;
    colormap(1-pink)
    xlabel('$\Gamma/\hat{q}_\mathrm{ref}$')
    ylabel('$\kappa_\mathrm{c}$')
    zlabel('$\hat{q}^\ast /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    set(gca,'YScale','log')
    xlim([simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
         simsetup.VariationCouplingAndClearance.Range_GammaScale(2)])
    ylim([simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
         simsetup.VariationCouplingAndClearance.Range_kappa_c(2)])
    zlim([-inf inf])
    savefig([savepath 'qhat_removed.fig'])

elseif (simsetup.VariationCouplingAndClearance.Number_GammaScale==1 && ...
        simsetup.VariationCouplingAndClearance.Number_kappa_c>1)

    % Tuned 
    figure(1);
    errorbar(kappa_c,qhat_tuned,qhat_tuned_std,'LineWidth',1.5,'Color',color.ies)
    hold on;
    title('Tuned system')
    box on;
    xlabel('$\kappa_\mathrm{c}$')
    ylabel('$\hat{q} /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    xlim([simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
         simsetup.VariationCouplingAndClearance.Range_kappa_c(2)])
    ylim([-inf inf])
    savefig([savepath 'qhat_tuned.fig'])
    
    % Fixed absorber
    figure(2);
    errorbar(kappa_c,qhat_fixed,qhat_fixed_std,'LineWidth',1.5,'Color',color.ies)
    hold on;
    title('Fixed absorber')
    box on;
    xlabel('$\kappa_\mathrm{c}$')
    ylabel('$\hat{q}^\ast /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    xlim([simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
         simsetup.VariationCouplingAndClearance.Range_kappa_c(2)])
    ylim([-inf inf])
    savefig([savepath 'qhat_fixed.fig'])
   
     % Fixed absorber
    figure(3);
    errorbar(kappa_c,qhat_removed,qhat_removed_std,'LineWidth',1.5,'Color',color.ies)
    hold on;
    title('Removed absorber')
    box on;
    xlabel('$\kappa_\mathrm{c}$')
    ylabel('$\hat{q}^\ast /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    xlim([simsetup.VariationCouplingAndClearance.Range_kappa_c(1),...
         simsetup.VariationCouplingAndClearance.Range_kappa_c(2)])
    ylim([-inf inf])
    savefig([savepath 'qhat_removed.fig'])

elseif (simsetup.VariationCouplingAndClearance.Number_GammaScale>1 && ...
        simsetup.VariationCouplingAndClearance.Number_kappa_c==1)
    
    % Tuned system
    figure(1);
    errorbar(Gamma_Scale,qhat_tuned,qhat_tuned_std,'LineWidth',1.5,'Color',color.ies)
    hold on;
    scatter(Gamma_Scale_min_tuned,qhat_min_tuned,50,'MarkerEdgeColor',color.show,...
        'MarkerFaceColor',color.show);
    title('Tuned system')
    box on;
    xlabel('$\Gamma/\hat{q}_\mathrm{ref}$')
    ylabel('$\hat{q} /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    axis tight;
    xlim([simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
         simsetup.VariationCouplingAndClearance.Range_GammaScale(2)])
    savefig([savepath 'qhat_tuned.fig'])


    % Fixed abosrber
    figure(2);
    errorbar(Gamma_Scale,qhat_fixed,qhat_fixed_std,'LineWidth',1.5,'Color',color.ies)
    hold on;
    scatter(Gamma_Scale_min_fixed,qhat_min_fixed,50,'MarkerEdgeColor',color.show,...
        'MarkerFaceColor',color.show);
    title('Fixed absorber')
    box on;
    xlabel('$\Gamma/\hat{q}_\mathrm{ref}$')
    ylabel('$\hat{q}^\ast /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    axis tight;
    xlim([simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
         simsetup.VariationCouplingAndClearance.Range_GammaScale(2)])
    savefig([savepath 'qhat_fixed.fig'])
    
    % Removed absorber
    figure(3);
    errorbar(Gamma_Scale,qhat_removed,qhat_removed_std,'LineWidth',1.5,'Color',color.ies)
    hold on;
    scatter(Gamma_Scale_min_removed,qhat_min_removed,50,'MarkerEdgeColor',color.show,...
        'MarkerFaceColor',color.show);
    title('Removed absorber')
    box on;
    xlabel('$\Gamma/\hat{q}_\mathrm{ref}$')
    ylabel('$\hat{q}^\ast /\hat{q}_\mathrm{ref}$')
    set(gca,'XScale','log')
    axis tight;
    xlim([simsetup.VariationCouplingAndClearance.Range_GammaScale(1),...
         simsetup.VariationCouplingAndClearance.Range_GammaScale(2)])
    savefig([savepath 'qhat_removed.fig'])
end