function [maxDur, sBest, eBest] = BelowThreshold(vpu)
thr = 0.95;

mask = vpu < thr;

mask(isnan(vpu)) = false;

d = diff([false; mask; false]);

s = find(d == 1);       
e = find(d == -1) - 1; 

if isempty(s)
    maxDur = 0;
    sBest  = NaN;
    eBest  = NaN;
    return
end

[ maxDur, idx ] = max(e - s + 1);

sBest = s(idx);
eBest = e(idx);

end
