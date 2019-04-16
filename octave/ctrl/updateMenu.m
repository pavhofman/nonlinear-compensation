function updateMenu(dirStruct, info)
  % setting distortion menu items visibility
  if isfield(info, 'distortHarmLevels') && ~isempty(info.distortHarmLevels)
    setEnabled(dirStruct.distortOnMenu, false);
    setEnabled(dirStruct.distortOffMenu, true);
  else
    setEnabled(dirStruct.distortOnMenu, true);
    setEnabled(dirStruct.distortOffMenu, false);
  endif
  
  % setting generation menu items visibility
  if isfield(info, 'genFunds') && ~isempty(info.genFunds)
    setEnabled(dirStruct.genOffMenu, true);
  else
    setEnabled(dirStruct.genOffMenu, false);
  endif
  
  global DIR_REC;
  if info.direction == DIR_REC
    % setting calibration menu items visibility/enabled
    global ANALYSING;
    if isfield(info.status, ANALYSING) && isResultOK(info.status.(ANALYSING).result)
      % analysis running successfully
      global CALIBRATING;
      if isfield(info.status, CALIBRATING)
        % calibration running
        setEnabled(dirStruct.calOffMenu, true);
        setEnabled(dirStruct.calSingleMenu, false);
        setEnabled(dirStruct.calContMenu, false);
      else
        % calibration not running
        setEnabled(dirStruct.calOffMenu, false);
        setEnabled(dirStruct.calSingleMenu, true);
        setEnabled(dirStruct.calContMenu, true);          
      endif
    else
      % no analysis succcessful, cannot run calibration
      setEnabled(dirStruct.calOffMenu, false);
      setEnabled(dirStruct.calSingleMenu, false);
      setEnabled(dirStruct.calContMenu, false);
    endif
  endif
  
  global FILE_SRC;
  if info.sourceStruct.src == FILE_SRC
    % is running from file
    setEnabled(dirStruct.readfileOffMenu, true);
  else
    setEnabled(dirStruct.readfileOffMenu, false);
  endif
  
  global MEMORY_SINK;  
  if structContains(info.sinkStruct, MEMORY_SINK)
    % is recording
    setEnabled(dirStruct.recordOffMenu, true);
    setEnabled(dirStruct.storeRecordedMenu, true);
  else
    setEnabled(dirStruct.recordOffMenu, false);
    setEnabled(dirStruct.storeRecordedMenu, false);
  endif
  
  if info.showingFFT
    setEnabled(dirStruct.fftMenu, false);
    setEnabled(dirStruct.fftOffMenu, true);
  else
    setEnabled(dirStruct.fftMenu, true);
    setEnabled(dirStruct.fftOffMenu, false);    
  endif
endfunction
