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

- in timer func, when plot (at start) is disabled, the program runs faster, need to check if anything important inside 