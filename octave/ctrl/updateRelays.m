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
  writeLog('DEBUG', "Setting %s relay (pin %d) to %d", relayName, pin, status);
  writeDigitalPin(ard, pin, status);
endfunction