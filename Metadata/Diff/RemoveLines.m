function im = RemoveLines(x)
    iml = size(x);
    immean = trimmean(x,40,2);
%     imstd = std(x(:));
%     mask = (abs(x)<1.5*imstd);
%     s = sum(mask');
%     s = s + (s==0);
%     immean = (sum((x.*mask)')./s)';
    rep = repmat(immean,1,iml(2));
    im = x-rep;
end