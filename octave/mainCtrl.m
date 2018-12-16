addpath(fileparts(mfilename('fullpath')));

clear;
source 'consts.m';

freq = 3000;
fs = 48000;

% measure filter (true) or calibrate all harmonics of freq
FILTER = true;

writeCmd("pass", CMD_FILE_PLAY);
writeCmd("pass", CMD_FILE_REC);
pause(1);


if (FILTER)
  % measuring LP filter at freq harmonics
  for f = (freq:freq:fs/2 - 1)
    printf("Generating %dHz\n", f);
    writeCmd(sprintf ("gen %d", f), CMD_FILE_PLAY);
    pause(2);
    printf("Measuring filter at %dHz\n", f);
    writeCmd(sprintf ("meas %d 2", f), CMD_FILE_REC);
    pause(1);  
  endfor
else
  % calibrating direct connection at freq harmonics
  for f = (freq:freq:fs/2 - 1)
    printf("Generating %dHz\n", f);
    writeCmd(sprintf ("gen %d", f), CMD_FILE_PLAY);
    pause(2);
    printf("Calibrating at %dHz\n", f);
    writeCmd("cal", CMD_FILE_REC);
    pause(1);  
  endfor
endif

writeCmd("pass", CMD_FILE_PLAY);
writeCmd("pass", CMD_FILE_REC);



