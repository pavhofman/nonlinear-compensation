function clbkStoreRec(src, data, cmdFile)
  global STORE_RECORDED;
  global CMD_FILEPATH_PREFIX;

  [fName, fDir] = uiputfile ({"*.wav;*.flac", "WAV, FLAC"}, 'Enter audio file to store the recording');
  if isnumeric(fName)
    % nothing selected, exiting
    return;
  endif
  
  fPath = [fDir fName];
  cmd = [STORE_RECORDED ' ' CMD_FILEPATH_PREFIX fPath];
  % sending command
  writeCmd(cmd, cmdFile, true);
endfunction
