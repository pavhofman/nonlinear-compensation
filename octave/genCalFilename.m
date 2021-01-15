% result: joint-sides version calDir/cal_freq1_freq2_FS48000_playDevName_CHchannelID_recDevName_CHchannelID_MchannelMode_extracircuit.dat
% split play-side version: calDir/cal_freq1_freq2_FS48000_playDevName_CHchannelID_MchannelMode_extracircuit.dat
% split rec-side version: calDir/cal_freq1_freq2_FS48000_recDevName_CHchannelID_MchannelMode_extracircuit.dat
function [filename, devSpecs] = genCalFilename(freqs, fs, compType, playChannelID, channelID, playCalDevName, recCalDevName, chMode, extraCircuit='')
  global dataDir;
  
  devSpecs = createCalFileDevSpecs(compType, playChannelID, channelID, playCalDevName, recCalDevName);
  
  % freq1_freq2_...
  freqsPart = '';
  for i = 1:length(freqs)
    % for now rounding freqs to int value
    freqsPart = sprintf('%s%d_', freqsPart,  round(freqs(i)));
  end
  
  filename = sprintf('cal_%sFS%d', freqsPart, fs);
  
  % wrap single-device devSpecs
  if rows(devSpecs) == 1
    devSpecs = {devSpecs};
  end
  for id = 1:rows(devSpecs)
    devSpec = devSpecs{id};
    filename = sprintf('%s_%s_CH%d', filename, devSpec{1}, devSpec{2});
  end
  
  % adding channel mode
  filename = sprintf('%s_M%d', filename, chMode);

  if length(extraCircuit) > 0
    filename = sprintf('%s_%s', filename, extraCircuit);
  end
  
  % suffix
  filename = sprintf('%s.dat', filename);

  filename = getFilePath(filename, dataDir);
end

% devSpec: rows of cells {devName, chID}
function devSpecs = createCalFileDevSpecs(compType, playChannelID, channelID, playCalDevName, recCalDevName)
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;

  switch compType
    case COMP_TYPE_JOINT
      devSpecs = {{playCalDevName, playChannelID}; {recCalDevName, channelID}};
    case COMP_TYPE_PLAY_SIDE
      devSpecs = {playCalDevName, channelID};
    case COMP_TYPE_REC_SIDE
      devSpecs = {recCalDevName, channelID};
  end
end


%!test
%! global COMP_TYPE_JOINT;
%! COMP_TYPE_JOINT = 0;
%! global COMP_TYPE_PLAY_SIDE;
%! COMP_TYPE_PLAY_SIDE = 1;
%! global COMP_TYPE_REC_SIDE;
%! COMP_TYPE_REC_SIDE = 2;
%!
%! global dataDir = '/tmp';
%! freqs = [1000; 2000];
%! fs = 48000;
%! compType = COMP_TYPE_JOINT;
%! playChannelID = 2;
%! channelID = 1;
%! chMode = 1;
%! extraCircuit = 'filter1';
%! expected = '/tmp/cal_1000_2000_FS48000_play8_CH2_rec8_CH1_M1_filter1.dat';
%! assert(expected, genCalFilename(freqs, fs, compType, playChannelID, channelID, 'play8', 'rec8', chMode, extraCircuit));
%!
%! compType = COMP_TYPE_REC_SIDE;
%! playChannelID = NA;
%! channelID = 1;
%! extraCircuit = '';
%! expected = '/tmp/cal_1000_2000_FS48000_rec8_CH1_M1.dat';
%! assert(expected, genCalFilename(freqs, fs, compType, playChannelID, channelID, '', 'rec8', chMode, extraCircuit));