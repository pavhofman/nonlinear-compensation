function updateRelays()
  global adapterStruct;
  global ardStruct;

  changed = setArdPin(ardStruct.ard, ardStruct.outPin, adapterStruct.out, 'Relay OFF/OUT');
  changed |= setArdPin(ardStruct.ard, ardStruct.calibLPFPin, adapterStruct.calibLPF, 'Relay VD/LPF');
  changed |= setArdPin(ardStruct.ard, ardStruct.inPin, adapterStruct.in, 'Relay CALIB/IN');

  if adapterStruct.has2LPFs
    % LPF1 = relay off = false, LPF2 = on = true
    changed |= setArdPin(ardStruct.ard, ardStruct.lpfPin,  adapterStruct.lpf == 2, 'Relay LPF1/LPF2');
  endif

  if adapterStruct.has2VDs
    % VD1 = relay off = false, VD2 = on = true
    changed |= setArdPin(ardStruct.ard, ardStruct.vdPin,  adapterStruct.vd == 2, 'Relay VD1/VD2');
  endif

  % switches are set now
  adapterStruct.switchesSet = true;
  % flag for change
  adapterStruct.switchesChanged |= changed;
endfunction