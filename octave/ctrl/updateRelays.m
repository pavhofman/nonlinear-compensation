function updateRelays()
  global adapterStruct;
  global ardStruct;

  changed = setRelay(ardStruct.ard, ardStruct.outPin, adapterStruct.out, 'OFF/OUT');
  changed |= setRelay(ardStruct.ard, ardStruct.calibLPFPin, adapterStruct.calibLPF, 'VD/LPF');
  changed |= setRelay(ardStruct.ard, ardStruct.inPin, adapterStruct.in, 'CALIB/IN');
  % LPF1 = relay off = false, LPF2 = on = true
  changed |= setRelay(ardStruct.ard, ardStruct.lpfPin,  adapterStruct.lpf == 2, 'LPF1/LPF2');

  % switches are set now
  adapterStruct.switchesSet = true;
  % flag for change
  adapterStruct.switchesChanged |= changed;
endfunction

function changed = setRelay(ard, pin, status, relayName)
  % empty matrix [pin1, status1; pin2, status2]
  persistent statuses = struct();
  pinName = sprintf("D%d", pin);

  if isfield(statuses, pinName) && statuses.(pinName) == status
    % already set, ignoring
    writeLog('TRACE', "Relay %s (pin %s) is already set to %d", relayName, pinName, status);
    changed = false;
  else
    % setting
    writeLog('DEBUG', "Setting relay %s (pin %s) to %d", relayName, pinName, status);
    ard._writeDigitalPin(pinName, status)
    % storing
    statuses.(pinName) = status;
    changed = true;
  endif
endfunction