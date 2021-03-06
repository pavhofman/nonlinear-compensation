% we cannot call 'clear all' since it clears all functions => also all breakpoints in functions
clear;
% clearing cached classes in Octave IDE
clear classes;

source 'consts.m';

addpath(currDir);
ctrlDir = [currDir filesep() 'ctrl'];
addpath(ctrlDir);
statusDir = [currDir filesep() 'status'];
addpath(statusDir);
internalDir = [currDir filesep() 'internal'];
addpath(internalDir);
ardDir = [ctrlDir filesep() 'arduino' filesep() 'inst'];
addpath(ardDir);


% we need some global settings - assuming recording direction (corresponding to configRec.m)
direction = DIR_REC;
global logPath;
logPath = stdout;

source 'run_common.m';

unwind_protect
  source ([ctrlDir filesep() 'run_ctrl.m']);
unwind_protect_cleanup
  % cleaning even when Ctrl+C
  if exist('fig', 'var') && isfigure(fig)
    close (fig);
  end
  if exist('recSock', 'var')
    zmq_close(recSock);
  end
  if exist('playSock', 'var')
    zmq_close(playSock);
  end
end_unwind_protect