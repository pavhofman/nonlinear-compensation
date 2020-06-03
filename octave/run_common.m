% script runs common code for mainRec/Play and mainCtrl. Creates required dirs, etc.

% no crash dumps
crash_dumps_octave_core(false);

if ~exist(dataDir, 'dir')
  mkdir(dataDir);
endif

if ~exist(logDir, 'dir')
  mkdir(logDir);
endif

if ~exist(commDir, 'dir')
  mkdir(commDir);
endif

if ~exist(transfDir, 'dir')
  mkdir(transfDir);
endif
