% devSpec: rows of cells {devName, chID}
function devSpecs = createCalFileDevSpecs(compType, playChannelID, channelID)
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;

  global inputDeviceName;
  global outputDeviceName;
  
  switch compType
    case COMP_TYPE_JOINT
      devSpecs = {{outputDeviceName, playChannelID}; {inputDeviceName, channelID}};
    case COMP_TYPE_PLAY_SIDE
      devSpecs = {outputDeviceName, channelID};
    case COMP_TYPE_REC_SIDE
      devSpecs = {inputDeviceName, channelID};
  endswitch
endfunction