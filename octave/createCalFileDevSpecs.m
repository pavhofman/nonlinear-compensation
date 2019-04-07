function devSpecs = createCalFileDevSpecs(compType, playChannelID, recChannelID)
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;

  global inputDeviceName;
  global outputDeviceName;
  
  switch compType:
    case COMP_TYPE_JOINT:
      devSpecs = {{outputDeviceName, playChannelID}; {inputDeviceName, recChannelID}};
    case COMP_TYPE_PLAY_SIDE:
      devSpecs = {outputDeviceName, playChannelID};
    case COMP_TYPE_REC_SIDE:
      devSpecs = {inputDeviceName, recChannelID};
  endswitch
endfunction