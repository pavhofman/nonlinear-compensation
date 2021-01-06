% script runs common code for mainRec/Play and mainCtrl. Creates required dirs, etc.

% no crash dumps
crash_dumps_octave_core(false);

if ~exist(dataDir, 'dir')
  mkdir(dataDir);
end

if ~exist(logDir, 'dir')
  mkdir(logDir);
end

if ~exist(commDir, 'dir')
  mkdir(commDir);
end

if ~exist(transfDir, 'dir')
  mkdir(transfDir);
end

if ~exist(confDir, 'dir')
  mkdir(confDir);
end
