# nanonis-connect
Improving the current Nanonis connection framework and thermal approach

Process to use Approach and Alt_Approach apps:
0) start Nanonis software
1) make sure there is a folder for the current date in C:\Users\Owner\Google Drive\4K microscope\data\YEAR\MON\DAY
and that the nanonis app is set to it
2) apply command General.Connect() in order to search for instruments 
3) run program

Bugs:
-on Retract the Zs step doesnt reset (should it?)
[V] evaluation error - was done from concratting cell array of chars with cell array of strings :( and device not connected
[] timer_func Plotting is slow because of calls to nanonis (AC can be reduced by storeing value, DC might be irellavant)
[] timer_func Plotting causes pauses in program because of addpoints (why?)
[] end of thermal approach there is pause(3) can we shorten it?
[] could the propegate motor cause pase ever N steps?
Features:
[] thermal initial * ratio > 10 => cant continue change sensitivity (when changing sensitivity ask Nofar how to log the change lockin)
[] every N extensions => tell user to check blob


