function updateMenu(dirStruct, info)
  % setting distortion menu items visibility
  if isfield(info, 'distortHarmLevels') && ~isempty(info.distortHarmLevels)
    setVisible(dirStruct.distortOnMenu, false);
    setVisible(dirStruct.distortOffMenu, true);
  else
    setVisible(dirStruct.distortOnMenu, true);
    setVisible(dirStruct.distortOffMenu, false);
  endif
  
  % setting generation menu items visibility
  if isfield(info, 'genFunds') && ~isempty(info.genFunds)
    setVisible(dirStruct.genOffMenu, true);
  else
    setVisible(dirStruct.genOffMenu, false);
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
        setVisible(dirStruct.calOffMenu, true);
        setEnabled(dirStruct.calSingleMenu, false);
        setEnabled(dirStruct.calContMenu, false);
      else
        % calibration not running
        setVisible(dirStruct.calOffMenu, false);
        setEnabled(dirStruct.calSingleMenu, true);
        setEnabled(dirStruct.calContMenu, true);          
      endif
    else
      % no analysis succcessful, cannot run calibration
      setVisible(dirStruct.calOffMenu, false);
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
