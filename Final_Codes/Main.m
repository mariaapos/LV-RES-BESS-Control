clear; close all; clc;

%% SIMULATION SETTINGS
% Control type:
% 1 = No Control
% 2 = Q-V Control 
% 3 = P-V Control 
% 4 = PF Control + Battery Charging/Discharnging Logic
control_type = 4;

% Battery Method
Bat_Method = 'CP';

% Voltage check scenario:
% 1 = Check Positive Sequence Only (V1)
% 2 = Check All 3 Phases (Va, Vb, Vc)
voltage_check_mode = 1; 

%% 
load('Interpolated_1min.mat');
load('Names.mat');
load('Saved_values.mat');
fprintf('Data files loaded successfully.\n');

PVBusNames = cellfun(@(s) strtok(s,'.'), PV_Bus(:,1), 'UniformOutput', false);

% PV Rated Power
PV_rated = [20, 30, 10, 15, 10, 20, 10];

% Loads Rated Powers
PLoadPhaseA_rated = [5, 7, 6, 6, 4, 3, 3, 3, 3, 3, 4];
PLoadPhaseB_rated = [0, 3, 3, 5, 3, 1, 0, 0, 4, 0, 3];
PLoadPhaseC_rated = [3, 6, 7, 6, 5, 4, 3, 0, 3, 0, 2];
QLoadPhaseA_rated = [1.5, 2, 2, 2.0, 2, 1.0, 1, 1, 2.0, 1, 1.5];
QLoadPhaseB_rated = [0.0, 1, 1, 1.5, 1, 0.5, 0, 0, 1.5, 0, 1.0];
QLoadPhaseC_rated = [1.0, 2, 2, 2.0, 2, 2.0, 1, 0, 1.0, 0, 1.0];

% Generate Profiles
nominal_mult = 2.5;
[Variable_Active_PowerA, Variable_Active_PowerB, Variable_Active_PowerC, Variable_Reactive_PowerA, Variable_Reactive_PowerB, Variable_Reactive_PowerC, PV_Power, PV_Profile] = Variable_Active_Reactive_PV_Power( PV_rated, PLoadPhaseA_rated, PLoadPhaseB_rated, PLoadPhaseC_rated, QLoadPhaseA_rated, QLoadPhaseB_rated, QLoadPhaseC_rated, nominal_mult);

% QV droop constants
Vmin = 0.95;
Vmax = 1.05;
dV = 0.04;

% Volt-Watt constants
V1_PV = 1.02;
V2_PV = 1.05;

% Controller memory
Qold_pv = zeros(7,1);
Pold_pv = zeros(7,1);

%% BATTERY PARAMETERS
Bat_kW_Rated  = [20, 15, 20, 15];      % total 3φ kW
Bat_kWh_Cap   = [80, 60, 80, 60];      % total pack kWh
SOC_State = ones(4, 1) * 0.5;          % ONE SoC per battery (4×1)
Vbat_nom = 400;                        % pack nominal voltage
Bat_Ah_Cap = (Bat_kWh_Cap * 1000) ./ Vbat_nom;  % Ah at pack voltage
SoC_max = 0.95;
SoC_min = 0.15;

%% 
DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
    error('OpenDSS failed to start');
end
DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSText.Command = ['Compile ', fullfile(pwd, 'grid.dss')];

%% MAIN LOOP
T_steps = length(Variable_Active_PowerA(:,1));
fprintf('Running Simulation: Control Type %d | Check Mode: %d\n', control_type, voltage_check_mode);

Voltage_Out_All.VAN_vec = nan(37, T_steps);
Voltage_Out_All.VBN_vec = nan(37, T_steps);
Voltage_Out_All.VCN_vec = nan(37, T_steps);
Voltage_Out_All.VAN_mag = nan(37, T_steps);
Voltage_Out_All.VBN_mag = nan(37, T_steps);
Voltage_Out_All.VCN_mag = nan(37, T_steps);
Voltage_Out_All.VAN_ang = nan(37, T_steps);
Voltage_Out_All.VBN_ang = nan(37, T_steps);
Voltage_Out_All.VCN_ang = nan(37, T_steps);

Nbus = length(BusNames);
Res_VA = nan(T_steps, Nbus);
Res_VB = nan(T_steps, Nbus);
Res_VC = nan(T_steps, Nbus);
Res_V1 = nan(T_steps, Nbus);
Res_SOC    = nan(T_steps, 4);          
Res_Bat_kW = zeros(T_steps, 4);        

V_prev_pu = ones(7, 1);

for k = 1:T_steps
   
    for i = 1:numel(LoadNames)
        DSSCircuit.SetActiveElement([LoadNames{i}, 'a']);
        DSSCircuit.ActiveElement.Properties('kW').Val   = num2str(Variable_Active_PowerA(k,i));
        DSSCircuit.ActiveElement.Properties('kvar').Val = num2str(Variable_Reactive_PowerA(k,i));
        DSSCircuit.SetActiveElement([LoadNames{i}, 'b']);
        DSSCircuit.ActiveElement.Properties('kW').Val   = num2str(Variable_Active_PowerB(k,i));
        DSSCircuit.ActiveElement.Properties('kvar').Val = num2str(Variable_Reactive_PowerB(k,i));
        DSSCircuit.SetActiveElement([LoadNames{i}, 'c']);
        DSSCircuit.ActiveElement.Properties('kW').Val   = num2str(Variable_Active_PowerC(k,i));
        DSSCircuit.ActiveElement.Properties('kvar').Val = num2str(Variable_Reactive_PowerC(k,i));
    end
    
    
    for j = 1:7
        P_gen = PV_Power(k, j); 
        Q_gen = 0;
        V_meas = V_prev_pu(j);
        
        if control_type == 1
            P_set = P_gen;
            Q_set = 0;
        elseif control_type == 2
            Pg = P_gen;              
            Pn = PV_rated(j);       
            Qdroop = QV(Pg, Pn, Vmin, Vmax, V_meas, Qold_pv(j), dV);
            Qold_pv(j) = Qdroop;
            Q_set = -Qdroop;
            P_set = P_gen;
        elseif control_type == 3
            Pn = P_gen;           
            Pold = Pold_pv(j);
            P_set = PV(Pn, V1_PV, V2_PV, V_meas, Pold);
            Pold_pv(j) = P_set;
            Q_set = 0;
        elseif control_type == 4
            if PV_Profile(k)>0.5
                pf =  -0.1*PV_Profile(k) + 1.05 ;
                ReactivePower = sqrt(((P_gen/pf)^2) - P_gen^2 );
            else
                ReactivePower=0;
            end
            P_set = P_gen;
            Q_set = ReactivePower;
        end
        
        kW_gen_per_phase   = (P_set) / 3;
        kvar_gen_per_phase = (-Q_set) / 3;
        phases = {'a','b','c'};
        for p = 1:3
            dss_name = [char(GenNames(j)), phases{p}];
            DSSCircuit.SetActiveElement(dss_name);
            DSSCircuit.ActiveElement.Properties('kW').Val   = num2str(kW_gen_per_phase);
            DSSCircuit.ActiveElement.Properties('kvar').Val = num2str(kvar_gen_per_phase);
        end
    end
    
    %% BATTERY 
    if control_type == 4
        % Charge 10am-4pm, Discharge 6pm-10pm
        mode = 'idle';
        if k >= 600 && k <= 960
            mode = 'charge';
        elseif k >= 1080 && k <= 1320
            mode = 'discharge';
        end
        for b = 1:4
            P_ref_total = Bat_kW_Rated(b);  
            Current_SOC = SOC_State(b); 
            switch Bat_Method
                case 'CP'
                    [P_ctrl, SOC_new] = CP(P_ref_total, Vbat_nom, Current_SOC, SoC_min, SoC_max, mode, 60, Bat_Ah_Cap(b));
                otherwise
                    warning('Invalid Battery Method Selected.');
                    return;
            end
            SOC_State(b) = SOC_new;
            Res_SOC(k,b) = SOC_State(b);
            Res_Bat_kW(k,b) = P_ctrl;
            
            if abs(P_ctrl) < 1e-6
                st = 'IDLING';
                kW_set_phase = 0;
            elseif P_ctrl > 0
                st = 'DISCHARGING';
                kW_set_phase = abs(P_ctrl) / 3;
            else
                st = 'CHARGING';
                kW_set_phase = P_ctrl / 3;
            end
               
            for ph = 1:3
                suffix = char(96+ph); 
                raw_name = [StorNames{b}, suffix];
                if strncmpi(raw_name, 'Storage.', 8)
                     full_name = raw_name;
                else
                     full_name = ['Storage.', raw_name];
                end
                if kW_set_phase < -1e-4
                    state_cmd = 'CHARGING';
                elseif kW_set_phase > 1e-4
                    state_cmd = 'DISCHARGING';
                else
                    state_cmd = 'IDLING';
                end
                cmdString = sprintf('Edit %s %%Stored=%.2f kW=%.4f State=%s', full_name, SOC_State(b)*100, kW_set_phase, state_cmd);
                DSSText.Command = cmdString;
            end
        end
    end
    
    DSSCircuit.Solution.Solve;
   
    if DSSCircuit.Solution.Converged
        Voltage_Out = voltage_extraction(BusNames, DSSCircuit.AllNodename, DSSCircuit.AllBusVolts);
        Voltage_Out_All.VAN_vec(:,k) = Voltage_Out.VAN_vec;
        Voltage_Out_All.VBN_vec(:,k) = Voltage_Out.VBN_vec;
        Voltage_Out_All.VCN_vec(:,k) = Voltage_Out.VCN_vec;
        Voltage_Out_All.VAN_mag(:,k) = Voltage_Out.VAN_mag;
        Voltage_Out_All.VBN_mag(:,k) = Voltage_Out.VBN_mag;
        Voltage_Out_All.VCN_mag(:,k) = Voltage_Out.VCN_mag;
        
        Va = Voltage_Out.VAN_vec;
        Vb = Voltage_Out.VBN_vec;
        Vc = Voltage_Out.VCN_vec;
        a = exp(1i * 2 * pi / 3);
        V1_vec = (Va + a*Vb + (a^2)*Vc) / 3;
        V_base = 690/sqrt(3);
        
        Va_pu = abs(Va) / V_base;
        Vb_pu = abs(Vb) / V_base;
        Vc_pu = abs(Vc) / V_base;
        V1_pu = abs(V1_vec) / V_base;
        
        Res_VA(k,:) = Va_pu(:).';
        Res_VB(k,:) = Vb_pu(:).';
        Res_VC(k,:) = Vc_pu(:).';
        Res_V1(k,:) = V1_pu(:).';
    end
    
    for j = 1:7
        idxPV = find(strcmpi(BusNames, PVBusNames{j}), 1);
        if ~isempty(idxPV)
            V_prev_pu(j) = V1_pu(idxPV);
        end
    end
end

%% WORST BUS DETECTION 
OV_thr = 1.05;
UV_thr = 0.95;
maxOV = 0; ovBus = NaN; 
maxUV = 0; uvBus = NaN; 

if voltage_check_mode == 1
    for i = 2:Nbus
        v = Res_V1(:,i);
        if all(isnan(v)), continue; end
        [ovDur, ~, ~] = AboveThreshold(v);
        [uvDur, ~, ~] = BelowThreshold(v);
        
        if ovDur > maxOV
            maxOV = ovDur; ovBus = i;
        end
        if uvDur > maxUV
            maxUV = uvDur; uvBus = i;
        end
    end
    
    if isnan(ovBus) && isnan(uvBus)
        [peakV, peakIdx] = max(max(Res_V1(:,2:end))); 
        [dipV, dipIdx]   = min(min(Res_V1(:,2:end))); 
        
        distToOV = OV_thr - peakV;
        distToUV = dipV - UV_thr;
        
        if distToOV < distToUV
            worstBus = peakIdx + 1; 
            eventTxt = sprintf('No OV/UV -> Worst by peak proximity (V1=%.3f)', peakV);
        else
            worstBus = dipIdx + 1;
            eventTxt = sprintf('No OV/UV -> Worst by dip proximity (V1=%.3f)', dipV);
        end
    else
        if maxOV >= maxUV
             worstBus = ovBus;
             eventTxt = sprintf('Worst OV Bus (Duration: %d min)', maxOV);
        else
             worstBus = uvBus;
             eventTxt = sprintf('Worst UV Bus (Duration: %d min)', maxUV);
        end
    end

elseif voltage_check_mode == 2
    for i = 2:Nbus
        vA = Res_VA(:,i); vB = Res_VB(:,i); vC = Res_VC(:,i);
        if all(isnan(vA)), continue; end
        
        [ovDurA, ~, ~] = AboveThreshold(vA); [uvDurA, ~, ~] = BelowThreshold(vA);

        [ovDurB, ~, ~] = AboveThreshold(vB); [uvDurB, ~, ~] = BelowThreshold(vB);

        [ovDurC, ~, ~] = AboveThreshold(vC); [uvDurC, ~, ~] = BelowThreshold(vC);
       
        currOV = max([ovDurA, ovDurB, ovDurC]);
        currUV = max([uvDurA, uvDurB, uvDurC]);
        
        if currOV > maxOV
            maxOV = currOV; ovBus = i;
        end
        if currUV > maxUV
            maxUV = currUV; uvBus = i;
        end
    end
    if isnan(ovBus) && isnan(uvBus)
      
        [peakA, idxPeakA] = max(max(Res_VA(:,2:end))); [dipA, idxDipA] = min(min(Res_VA(:,2:end)));
        [peakB, idxPeakB] = max(max(Res_VB(:,2:end))); [dipB, idxDipB] = min(min(Res_VB(:,2:end)));
        [peakC, idxPeakC] = max(max(Res_VC(:,2:end))); [dipC, idxDipC] = min(min(Res_VC(:,2:end)));
        
        globalPeak = max([peakA, peakB, peakC]);
        globalDip  = min([dipA, dipB, dipC]);
        
        distToOV = OV_thr - globalPeak;
        distToUV = globalDip - UV_thr;
        
        if distToOV < distToUV
            if globalPeak == peakA, worstBus = idxPeakA + 1;
            elseif globalPeak == peakB, worstBus = idxPeakB + 1;
            else, worstBus = idxPeakC + 1;
            end
            eventTxt = sprintf('No OV/UV -> Worst by peak (%.3f pu)', globalPeak);
        else
            if globalDip == dipA, worstBus = idxDipA + 1;
            elseif globalDip == dipB, worstBus = idxDipB + 1;
            else, worstBus = idxDipC + 1;
            end
            eventTxt = sprintf('No OV/UV -> Worst by dip (%.3f pu)', globalDip);
        end
    else
        if maxOV >= maxUV
             worstBus = ovBus;
             eventTxt = sprintf('Worst OV Bus (Duration: %d min)', maxOV);
        else
             worstBus = uvBus;
             eventTxt = sprintf('Worst UV Bus (Duration: %d min)', maxUV);
        end
    end
end

fprintf('Selected Worst Bus for Plotting: %s (idx %d) [%s]\n', BusNames{worstBus}, worstBus, eventTxt);

% Plotting worst bus
figure('Color','w');
time_ax = 1:T_steps;
plot(time_ax, Res_VA(:,worstBus), 'r', 'LineWidth', 1.5); hold on;
plot(time_ax, Res_VB(:,worstBus), 'b', 'LineWidth', 1.5);
plot(time_ax, Res_VC(:,worstBus), 'k', 'LineWidth', 1.5);
plot(time_ax, Res_V1(:,worstBus), 'g', 'LineWidth', 2);
yline(OV_thr, '--m', 'LineWidth', 1.5, 'Label', 'Upper Limit');
yline(UV_thr, '--m', 'LineWidth', 1.5, 'Label', 'Lower Limit');
legend('Phase A','Phase B','Phase C','Pos. Seq.','Limits');
xlabel('Time t (Minutes)');
ylabel('Voltage (p.u.)');
title(sprintf('%s – Bus %s (idx %d)', eventTxt, BusNames{worstBus}, worstBus));
grid on;
xlim([1 1440]);
ylim([0.9 1.1]);

% Plot SoC
figure('Color','w');
plot(1:T_steps, Res_SOC, 'LineWidth', 1.5);
grid on;
xlim([1 1440]);
ylim([0 1]);
xlabel('Time (min)');
ylabel('SoC');
legend('Bat1','Bat2','Bat3','Bat4');
title('Battery SoC');