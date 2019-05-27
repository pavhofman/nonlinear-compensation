% script runs common code for mainRec/Play and mainCtrl. Defines global device names, creates required dirs, etc.
% Requires loaded configRec.m files

% no crash dumps
crash_dumps_octave_core(false);

if ~exist(dataDir, 'dir')
  mkdir(dataDir);
endif

source 'set_device_names.m';