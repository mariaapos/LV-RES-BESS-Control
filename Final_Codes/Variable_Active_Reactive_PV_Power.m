function [Variable_Active_PowerA, Variable_Active_PowerB, Variable_Active_PowerC, Variable_Reactive_PowerA, Variable_Reactive_PowerB, Variable_Reactive_PowerC, PV_Power, PV_Profile] = Variable_Active_Reactive_PV_Power(PV_rated, PLoad_ratedA, PLoad_ratedB, PLoad_ratedC, QLoad_ratedA, QLoad_ratedB, QLoad_ratedC, nominal_mult)

    load('Interpolated_1min.mat');

    min_consumption = 0.2322;
    max_diff_con    = 0.4742;
    max_generation  = 1;
    max_diff_gen    = 0.9944;

    % Active power loads (3 phases)
    for m = 1:11   % 11 is the number of loads in the examined grid
        Variable_Active_PowerA(:, m) = 0.84 * PLoad_ratedA(m) * consumption_1min;
        Variable_Active_PowerB(:, m) = 0.84 * PLoad_ratedB(m) * consumption_1min;
        Variable_Active_PowerC(:, m) = 0.84 * PLoad_ratedC(m) * consumption_1min;
    end

    % Reactive power loads (3 phases)
    for m = 1:11   % 11 is the number of loads in the examined grid
        Variable_Reactive_PowerA(:, m) = 0.84 * QLoad_ratedA(m) * consumption_1min;
        Variable_Reactive_PowerB(:, m) = 0.84 * QLoad_ratedB(m) * consumption_1min;
        Variable_Reactive_PowerC(:, m) = 0.84 * QLoad_ratedC(m) * consumption_1min;
    end

    % PV generation
    for m = 1:7    % 7 is the number of PVs in the examined grid
        PV_Power(:, m) = nominal_mult * PV_rated(m) * generation_1min + 0.001;
    end

    PV_Profile = generation_1min;

end
