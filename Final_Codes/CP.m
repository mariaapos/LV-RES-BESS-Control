function [P_kW, SoC_final] = CP(P_ref_kW, Vbat, SoC_initial, SoC_min, SoC_max, mode, dt_sec, Q_cap_Ah)

    P_kW = 0;
    SoC_final = SoC_initial;

    if dt_sec <= 0 || Q_cap_Ah <= 0 || Vbat <= 0
        warning('CP:BadParams','Invalid parameters. Returning 0 power.');
        return;
    end

    if strcmp(mode,'idle') || strcmp(mode,'standby')
        return;
    end

    dt_hr = dt_sec / 3600;
    E_cap_kWh = (Q_cap_Ah * Vbat) / 1000;   % Ah*V = Wh -> kWh

    if strcmp(mode,'charge')
        if SoC_initial >= SoC_max, return; end

        E_room_kWh = (SoC_max - SoC_initial) * E_cap_kWh;
        Pmax_kW = E_room_kWh / dt_hr;
        Pcmd_kW = min(P_ref_kW, max(Pmax_kW, 0));
        P_kW = -Pcmd_kW;

    elseif strcmp(mode,'discharge')
        if SoC_initial <= SoC_min, return; end

        E_avail_kWh = (SoC_initial - SoC_min) * E_cap_kWh;
        Pmax_kW = E_avail_kWh / dt_hr;
        Pcmd_kW = min(P_ref_kW, max(Pmax_kW, 0));
        P_kW = +Pcmd_kW;

    else
        warning('CP:InvalidMode','Invalid mode. Returning 0 power.');
        return;
    end

    SoC_final = SoC_initial - (P_kW * dt_hr) / E_cap_kWh;
    SoC_final = min(max(SoC_final, 0), 1);
end