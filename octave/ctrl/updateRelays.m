function updateRelays()
  global adapterStruct;
  global ardStruct;

  setRelay(ardStruct.ard, ardStruct.outPin, adapterStruct.out, 'OFF/OUT');
  setRelay(ardStruct.ard, ardStruct.lpfPin, adapterStruct.lpf, 'VD/LPF');
  setRelay(ardStruct.ard, ardStruct.inPin, adapterStruct.in, 'CALIB/IN');

  % switches are set now
  adapterStruct.switchesSet = true;
endfunction

function setRelay(ard, pin, status, relayName)
  pinName = sprintf("D%d", pin);
  writeLog('DEBUG', "Setting %s relay (pin %s) to %d", relayName, pinName, status);
  ard._writeDigitalPin(pinName, status)
endfunction