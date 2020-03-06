function updateRelays()
  global adapterStruct;
  global ardStruct;

  setRelay(ardStruct.ard, ardStruct.outPin, adapterStruct.out, 'OUT/OFF');
  setRelay(ardStruct.ard, ardStruct.vdPin, adapterStruct.lpf, 'LPF/VD');
  setRelay(ardStruct.ard, ardStruct.calibratePin, adapterStruct.in, 'IN/CALIB');

  % switches are set now
  global switchesSet;
  switchesSet = true;
endfunction

function setRelay(ard, pin, status, relayName)
  pinName = sprintf("D%d", pin);
  writeLog('DEBUG', "Setting %s relay (pin %s) to %d", relayName, pinName, status);
  ard._writeDigitalPin(pinName, status)
endfunction