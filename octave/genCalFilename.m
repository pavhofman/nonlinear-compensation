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
    freqsPart = [freqsPart,  int2str(round(freqs(i))), '_'];
  endfor
  
  filename = ['cal_' freqsPart 'FS' int2str(fs)];
  
  % wrap single-device devSpecs
  if rows(devSpecs) == 1
    devSpecs = {devSpecs};
  endif
  for id = 1:rows(devSpecs)
    devSpec = devSpecs{id};
    filename = [filename '_' devSpec{1} '_CH' int2str(devSpec{2})];
  endfor
  
  %% TODO - for now ignoring chMode in calfile names (the current implementation is incorrect)
  % adding channel mode
  %filename = [filename '_M' num2str(chMode)];

  if length(extraCircuit) > 0
    filename = [filename '_' extraCircuit];
  endif
  
  % suffix
  filename = [filename '.dat'];

  filename = getFilePath(filename, dataDir);
endfunction

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
  endswitch
endfunction


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
%! expected = '/tmp/cal_1000_2000_FS48000_play8_CH2_rec8_CH1_filter1.dat';
%! assert(expected, genCalFilename(freqs, fs, compType, playChannelID, channelID, 'play8', 'rec8', chMode, extraCircuit));
%!
%! compType = COMP_TYPE_REC_SIDE;
%! playChannelID = NA;
%! channelID = 1;
%! extraCircuit = '';
%! expected = '/tmp/cal_1000_2000_FS48000_rec8_CH1.dat';
%! assert(expected, genCalFilename(freqs, fs, compType, playChannelID, channelID, '', 'rec8', chMode, extraCircuit));