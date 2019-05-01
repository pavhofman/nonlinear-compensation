function updateMenu(dirStruct, info)
  % running only once a second
  persistent UPDATE_INTERVAL = 1;
  persistent lastUpdateTime = time();
  
  
  curTime = time();
  if curTime() > lastUpdateTime + UPDATE_INTERVAL
    lastUpdateTime = curTime;
  else
    return;
  endif
    
  % setting distortion menu items visibility
  if isfield(info, 'distortHarmAmpls') && ~isempty(info.distortHarmAmpls)
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
        setEnabled(dirStruct.calOnMenus, false);
        setEnabled(dirStruct.calOffMenus, true);
      else
        % calibration not running
        setEnabled(dirStruct.calOnMenus, true);
        setEnabled(dirStruct.calOffMenus, false);
      endif
    else
      % no analysis succcessful, cannot run calibration
      setEnabled(dirStruct.calOnMenus, false);
      setEnabled(dirStruct.calOffMenus, false);
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
