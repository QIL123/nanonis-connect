function y = tvFilter(x)
% total variation filter
M1 = x;
y = zeros(size(M1));
for jj = 1:1
    M2 = RemoveLines(M1);
    M3 = ROFdenoise(M2,3);
    y = y + M3;
    M1 = x-y;
end