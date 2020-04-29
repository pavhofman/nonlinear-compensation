% setting pin  e.g. 'D5' to status (0, 1). Param name used for loggging, at level logLevel
function changed = setArdPin(ard, pin, status, name, logLevel='DEBUG')
  % empty matrix [pin1, status1; pin2, status2]
  persistent statuses = struct();

  if isfield(statuses, pin) && statuses.(pin) == status
    % already set, ignoring
    % writeLog('TRACE', "%s (pin %s) is already set to %d", name, pinStr, status);
    changed = false;
  else
    % setting
    writeLog(logLevel, "Setting %s (pin %s) to %d", name, pin, status);
    ard._writeDigitalPin(pin, status)
    % storing
    statuses.(pin) = status;
    changed = true;
  endif
endfunction