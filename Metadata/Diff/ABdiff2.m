function [y,ShiftI] = ABdiff2(I1,I2)
    I1f = wlFilter(I1);
    I2f = wlFilter(I2);
    
    ShiftI = ABalign(I1f,I2f);
    Shifts = [[0;0] ShiftI];
    Marray{1}.data = I1;
    Marray{2}.data = I2;
    Marray = imSetCrop(Shifts,Marray);  
    i3 = Marray{1}.sdata;
    i4 = Marray{2}.sdata;

%    [rew,raw] = ltsregres(i4(:),i3(:));
%    i5 = rew.int + rew.slope*i4;
    %y = i5-i3;
        %Make a fit
    fOptions = fitoptions('Method','NonlinearLeastSquares','startPoint',[ 1 0], 'Lower', [0.8, -Inf], 'Upper', [1.2, Inf]);
    fType=fittype('alpha*x+beta','options',fOptions);
    [cfun,gof] =fit(i4(:),i3(:),fType);
    %RSquare = gof.rsquare; %print rsquare
    %param_error = confint(cfun);
    alpha = cfun.alpha;
    beta = cfun.beta;
    i5 = beta + alpha*i4;
    y = i3-i5;
    y = tvFilter(y);
end