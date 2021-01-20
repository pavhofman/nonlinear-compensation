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
    changed |= setArdPin(ardStruct.ard, ardStruct.balSePin,  adapterStruct.isSE, 'Relay BAL/SE');

    changed |= setArdPin(ardStruct.ard, ardStruct.groundPlusPin,  adapterStruct.groundPlus, 'Relay IN+GND');
    changed |= setArdPin(ardStruct.ard, ardStruct.groundMinusPin,  adapterStruct.groundMinus, 'Relay IN-GND');

    % switches are set now
    adapterStruct.switchesSet = true;
    % flag for change
    adapterStruct.switchesChanged |= changed;
    if changed && adapterStruct.adapterPanelDrawn
      updateAdapterPanel();
    end
  end
end