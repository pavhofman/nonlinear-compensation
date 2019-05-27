% we cannot call 'clear all' since it clears all functions => also all breakpoints in functions
clear;

currDir = fileparts(mfilename('fullpath'));
addpath(currDir);
ctrlDir = [currDir filesep() 'ctrl'];
addpath(ctrlDir);
statusDir = [currDir filesep() 'status'];
addpath(statusDir);
internalDir = [currDir filesep() 'internal'];
addpath(internalDir);

source 'consts.m';

% we need some global settings - assuming recording direction (corresponding to configRec.m)
direction = DIR_REC;
global logPath;
logPath = stdout;

source 'configRec.m';
source 'init_sourcestruct.m';
source 'run_common.m';

unwind_protect
  source ([ctrlDir filesep() 'run_ctrl.m']);
unwind_protect_cleanup
  % cleaning even when Ctrl+C
  if exist('fig', 'var') && isfigure(fig)
    close (fig);
  endif
  if exist('recSock', 'var')
    zmq_close(recSock);
  endif
  if exist('playSock', 'var')
    zmq_close(playSock);
  endif
end_unwind_protect