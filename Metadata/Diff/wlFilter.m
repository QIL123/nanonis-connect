function out = wlFilter(in)
level = 1;
let = 'coif2';

[c,s] = wavedec2(in,level,let); %<-
%     [chd1,cvd1,cdd1] = detcoef2('all',c,s,level);
%hh1 = wrcoef2('h',c,s,let,level);
%hv1 = wrcoef2('v',c,s,let,level);
%hd1 = wrcoef2('d',c,s,let,level);
%cha1 = appcoef2(c,s,let,level);
ha1 = wrcoef2('a',c,s,let,level);%<-

% [thr, sorh,keepapp] = ddencmp('den','wp',in);
% ha1 = wdencmp('gbl',in,let,level, thr, sorh,keepapp);

out = ha1;