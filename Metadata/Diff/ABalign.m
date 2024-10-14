function ShiftI = ABalign(I1,I2)
    p=.5; % cut
    S_1 = size(I1); %template
    S_2 = size(I2);

    Xcor=normxcorr2(I1, I2);
    m=max(Xcor(:));
    [k1,k2]=find(Xcor==m);
    Guess = [k1,k2]-S_2;

    s1 = floor(p*S_1(1)/2);    s2 = floor(S_1(1)-p*S_1(1)/2);
    s3 = floor(p*S_1(2)/2);    s4 = floor(S_1(2)-p*S_1(2)/2);
    [X1_1, X2_1] = ndgrid(1:S_1(1),1:S_1(2));
    F1 = griddedInterpolant(X1_1,X2_1,I1, 'spline');
    [s5,s6] = ndgrid(s1:s2,s3:s4);
    temp = F1(s5,s6);
    [X1_2, X2_2] = ndgrid(1:S_2(1),1:S_2(2));
    F2 = griddedInterpolant(X1_2,X2_2,I2, 'spline');
    s1 = floor(p*S_2(1)/2);    s2 = floor(S_2(1)-p*S_2(1)/2);
    s3 = floor(p*S_2(2)/2);    s4 = floor(S_2(2)-p*S_2(2)/2);
    
    function m = sF(a)
        [s5,s6] = ndgrid(s1:s2,s3:s4);
        s5 = s5+a(1); s6 = s6 + a(2);
        func = F2(s5,s6);
        %m = sum(abs(temp(:)-func(:)));
        tm3 = trimmean(func(:),40);
        tm5 = trimmean(temp(:),40);
        m = sum(abs((2*((func(:)-tm3)>0)-1)-(2*((temp(:)-tm5)>0)-1)));
    end
    psoptimset
    options = psoptimset;
    options = psoptimset(options,'TolMesh',1.0000e-08,'TolX',1.0000e-08,'TolFun',1.0000e-08);
    x = @(n3,n4) arrayfun( @(n1,n2) patternsearch(@sF, [n1; n2],[],[],[],[],[],[],options),n3,n4,'UniformOutput',false);%, optimset('TolX',1e-10));
    xres = x(Guess(1),Guess(2));
    fres = sF(xres{1});
    xres2 = x(0,0);
    fres2 = sF(xres2{1});
    if fres<fres2
        ShiftI = xres{1};
    else
        ShiftI = xres2{1};
    end
end