function Voltage = voltage_extraction(BusNames, NodeNames, allBusVolts)

lb = length(BusNames);

Vcomplex = allBusVolts(1:2:end) + 1i*allBusVolts(2:2:end);

VAn = nan(lb,1) + 1i*nan(lb,1);
VBn = nan(lb,1) + 1i*nan(lb,1);
VCn = nan(lb,1) + 1i*nan(lb,1);

NodeNamesL = lower(string(NodeNames));

for x = 1:lb
    b = lower(string(BusNames{x}));
    idx1 = find(NodeNamesL == (b + ".1"), 1);
    idx2 = find(NodeNamesL == (b + ".2"), 1);
    idx3 = find(NodeNamesL == (b + ".3"), 1);

    if ~isempty(idx1), VAn(x) = Vcomplex(idx1); end
    if ~isempty(idx2), VBn(x) = Vcomplex(idx2); end
    if ~isempty(idx3), VCn(x) = Vcomplex(idx3); end
end

Voltage.VAN_vec = VAn; Voltage.VBN_vec = VBn; Voltage.VCN_vec = VCn;
Voltage.VAN_mag = abs(VAn); Voltage.VBN_mag = abs(VBn); Voltage.VCN_mag = abs(VCn);
Voltage.VAN_ang = rad2deg(angle(VAn));
Voltage.VBN_ang = rad2deg(angle(VBn));
Voltage.VCN_ang = rad2deg(angle(VCn));
end
