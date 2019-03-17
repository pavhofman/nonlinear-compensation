function clbkReadFile(src, data, cmdFile)
  global READFILE;
  global CMD_FILEPATH_PREFIX;

  [fName, fDir] = uigetfile ({"*.wav;*.flac;*.ogg", "Supported Audio Formats"}, 'Select audio file to play');
  if isnumeric(fName)
    % nothing selected, exiting
    return;
  endif
  
  fPath = [fDir fName];
  cmd = [READFILE ' ' CMD_FILEPATH_PREFIX fPath];
  % sending command
  writeCmd(cmd, cmdFile, true);
endfunction
