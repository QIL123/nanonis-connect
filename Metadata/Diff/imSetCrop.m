function Marray = imSetCrop(Shifts,Marray)
% Input:
% Marray{j}.data - j=1:N - N images
% Shifts = [[0;0] ShiftI(1) ShiftI(2),...] - an array of shifts
% Output:
% Maaray{j}.data - the original data
% Maaray{j}.sdata - cropped images

isize = size(Marray{1}.data);
CS = cumsum(Shifts,2);
[X1_1, X2_1] = ndgrid(1:isize(1),1:isize(2));
for j=1:length(Marray)
    CS = CS - repmat(CS(:,j),1,length(Marray));
    maxCS = max(CS');
    minCS = min(CS');
    a1 = (1-minCS(1)):(isize(1)-maxCS(1)+minCS(1)-1)/(isize(1)-1):(isize(1)-maxCS(1));
    a2 = (1-minCS(2)):(isize(2)-maxCS(2)+minCS(2)-1)/(isize(2)-1):(isize(2)-maxCS(2));
    [s5,s6] = ndgrid(a1,a2);
    F2 = griddedInterpolant(X1_1,X2_1,Marray{j}.data, 'linear');
    Marray{j}.sdata = F2(s5,s6);
end

end