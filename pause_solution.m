function pause_solution(t)
% Like pause(t) but overcome the resolution of 15 ms on certain Windows OS
% NOTE: current thread is not really suspended
tms = floor(t*1000);
if tms == 0
    pause(t);
else
    t0=tic;
    for i=1:tms
        pause(0.001);
        telapse = toc(t0);
        if telapse > t
            break
        end
    end
    tremain = t-telapse;
    if tremain > 0
        pause(min(tremain,0.001)); % pause only accurate less than 1ms
    end
end
end
