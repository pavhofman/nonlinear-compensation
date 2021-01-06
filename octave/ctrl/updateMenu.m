function updateMenu(dirStruct, infoStruct)
  % running only once a second
  persistent UPDATE_INTERVAL = 1;
  % for each direction
  persistent lastUpdateTimes = cell(2, 1);
  
  
  curTime = time();
  % checking for each direction independently
  direction = infoStruct.direction;
  if isempty(lastUpdateTimes{direction}) ||  (curTime > lastUpdateTimes{direction} + UPDATE_INTERVAL)
    lastUpdateTimes{direction} = curTime;
  else
    return;
  end
    
  % setting distortion menu items visibility
  if isfield(infoStruct, 'distortHarmAmpls') && ~isempty(infoStruct.distortHarmAmpls)
    setEnabled(dirStruct.distortOnMenu, false);
    setEnabled(dirStruct.distortOffMenu, true);
  else
    setEnabled(dirStruct.distortOnMenu, true);
    setEnabled(dirStruct.distortOffMenu, false);
  end
  
  % setting generation menu items visibility
  if isfield(infoStruct, 'genFunds') && ~isempty(infoStruct.genFunds)
    setEnabled(dirStruct.genOffMenu, true);
  else
    setEnabled(dirStruct.genOffMenu, false);
  end
  
  global DIR_REC;
  if infoStruct.direction == DIR_REC
    % setting calibration menu items visibility/enabled
    global ANALYSING;
    if isfield(infoStruct.status, ANALYSING) && isResultOK(infoStruct.status.(ANALYSING).result)
      % analysis running successfully
      global CALIBRATING;
      if isfield(infoStruct.status, CALIBRATING)
        % calibration running
        setEnabled(dirStruct.calOnMenus, false);
        setEnabled(dirStruct.calOffMenus, true);
      else
        % calibration not running
        setEnabled(dirStruct.calOnMenus, true);
        setEnabled(dirStruct.calOffMenus, false);
      end
    else
      % no analysis succcessful, cannot run calibration
      setEnabled(dirStruct.calOnMenus, false);
      setEnabled(dirStruct.calOffMenus, false);
    end
  end
  
  global FILE_SRC;
  if infoStruct.sourceStruct.src == FILE_SRC
    % is running from file
    setEnabled(dirStruct.readfileOffMenu, true);
  else
    setEnabled(dirStruct.readfileOffMenu, false);
  end
  
  global MEMORY_SINK;  
  if structContains(infoStruct.sinkStruct, MEMORY_SINK)
    % is recording
    setEnabled(dirStruct.recordOffMenu, true);
    setEnabled(dirStruct.storeRecordedMenu, true);
  else
    setEnabled(dirStruct.recordOffMenu, false);
    setEnabled(dirStruct.storeRecordedMenu, false);
  end
  
  if infoStruct.showingFFT
    setEnabled(dirStruct.fftMenu, false);
    setEnabled(dirStruct.fftOffMenu, true);
  else
    setEnabled(dirStruct.fftMenu, true);
    setEnabled(dirStruct.fftOffMenu, false);    
  end
end
