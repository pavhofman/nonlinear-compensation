function clbkReadFile(src, data, cmdFile)
  global READFILE;
  global CMD_FILEPATH_PREFIX;

  [taskFName, fDir] = uigetfile ({"*.wav;*.flac;*.ogg", "Supported Audio Formats"}, 'Select audio file to play');
  if isnumeric(taskFName)
    % nothing selected, exiting
    return;
  endif
  
  fPath = [fDir taskFName];
  cmd = [READFILE ' ' CMD_FILEPATH_PREFIX fPath];
  % sending command
  writeCmd(cmd, cmdFile, true);
endfunction
