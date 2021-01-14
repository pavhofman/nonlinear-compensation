function updateRelays()
  global adapterStruct;
  % only for relay adapter
  if adapterStruct.hasRelays
    global ardStruct;

    changed = setArdPin(ardStruct.ard, ardStruct.outPin, adapterStruct.out, 'Relay OFF/OUT');
    changed |= setArdPin(ardStruct.ard, ardStruct.vdLpfPin, adapterStruct.vdLpf, 'Relay VD/LPF');
    changed |= setArdPin(ardStruct.ard, ardStruct.inPin, adapterStruct.in, 'Relay CALIB/IN');

    % LPF1 = relay off = false, LPF2 = on = true
    changed |= setArdPin(ardStruct.ard, ardStruct.lpfPin,  adapterStruct.lpf == 2, 'Relay LPF1/LPF2');

    % VD1 = relay off = false, VD2 = on = true
    changed |= setArdPin(ardStruct.ard, ardStruct.vdPin,  adapterStruct.vd == 2, 'Relay VD1/VD2');

    % BAL = relay off, SE = relay on
    changed |= setArdPin(ardStruct.ard, ardStruct.balSePin,  adapterStruct.modeSE, 'Relay BAL/SE');

    % switches are set now
    adapterStruct.switchesSet = true;
    % flag for change
    adapterStruct.switchesChanged |= changed;
  end
end