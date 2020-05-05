function updateLedsAndSwitch(recInfo, playInfo)
  persistent OFF = 0;
  persistent ON = 1;
  persistent SLOW_BLINK = 2;
  persistent FAST_BLINK = 3;

  persistent LONG_PUSH_MIN = 0.5; % sec


  global COMPENSATING;
  global CALIBRATING;

  global adapterStruct;
  global gpios;
  global ardStruct;
  global taskFNames;

  % LEDs
  if adapterStruct.out
    gpios.out.status = ifelse(~isempty(playInfo) && structContains(playInfo.status, COMPENSATING), SLOW_BLINK, ON);
  else
    gpios.out.status = OFF;
  endif

  if adapterStruct.in
    gpios.in.status = ifelse(~isempty(recInfo) && structContains(recInfo.status, COMPENSATING), SLOW_BLINK, ON);
  else
    gpios.in.status = OFF;
  endif

  if any(strcmp(taskFNames, 'splitCalibPlaySched'))
    % splitCalibPlaySched running
    ctrlActiveStatus = FAST_BLINK;
  elseif ~isempty(taskFNames) || (~isempty(recInfo) && structContains(recInfo.status, CALIBRATING))
    % any other task running or calibration - slow blinking
    ctrlActiveStatus = SLOW_BLINK;
  else
    ctrlActiveStatus = ON;
  endif

  if isAnalysisOK(playInfo) && isAnalysisOK(recInfo)
    % ctrl1 green OK
    gpios.ctrl1.status = ctrlActiveStatus;
    % ctrl red OFF
    gpios.ctrl2.status = OFF;
  else
    gpios.ctrl2.status = ctrlActiveStatus;
    gpios.ctrl1.status = OFF;
  endif


  % updating LED pins
  now = time();
  % 0.5 sec period
  slowBlinkValue = floor(rem(2 * now, 2));
  % 0.2 period
  fastBlinkValue = floor(rem(5 * now, 2));

  for [ledStruct, key] = gpios
    % ugly hack
    if strcmp(key, 'sw')
      % not LED
      continue;
    endif

    ledStatus = ledStruct.status;
    if ledStatus <= 1
      value = ledStatus;
    elseif ledStatus == SLOW_BLINK
      value = slowBlinkValue;
    elseif ledStatus == FAST_BLINK
      value = fastBlinkValue;
    else
      % default just in case
      pinStatus = 0;
    endif

    setArdPin(ardStruct.ard, ledStruct.pin, value, key, 'TRACE');
  endfor


  % switch handling
  % when a task is running, the switch works as ABORT
  % otherwise short press - range-calib task
  % long press - splitting task

  swValue = ardStruct.ard._readDigitalPin(gpios.sw.pin);
  writeLog('TRACE', 'Button value: %d', swValue);
  % switch has pullup, i.e. 0 = pushed
  if ~swValue
    % pushed
    if isna(gpios.sw.pushedSince)
      % first cycle when pushed, storing pushedSince time
      gpios.sw.pushedSince = time();
    endif
  else
    % not pushed
    if ~isna(gpios.sw.pushedSince)
      % just released
      longPush = (now -  gpios.sw.pushedSince) > LONG_PUSH_MIN ;
      % clearing flag
      gpios.sw.pushedSince = NA;
      if isempty(taskFNames)
        if longPush
          writeLog('DEBUG', 'Button pushed long - running splitCalibPlaySched');
          splitCalibPlaySched()
        else
          writeLog('DEBUG', 'Button pushed short - running exactCalibRecSched');
          exactCalibRecSched();
        endif
      else
        writeLog('DEBUG', 'Button pushed while tasks running - aborting');
        abortLastTask();
      endif
    endif % just released
  endif % not pushed

endfunction

function result = isAnalysisOK(info)
  global ANALYSING;
  if ~isempty(info) && isfield(info.status, ANALYSING)
    statusVal = info.status.(ANALYSING);
    if isfield(statusVal, 'result')
      result = statusVal.result;
      if isResultOK(result)
        result = true;
        % ending
        return;
      endif
    endif
  endif

  % not found or failed result
  result = false;
endfunction
