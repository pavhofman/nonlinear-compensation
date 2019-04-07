% devSpec: rows of cells {devName, chID} - see the test: devSpecs = { {'play8', 2}; {'rec8', 1}} OR devSpecs = {'rec8', 1};
% result: joint-sides version calDir/cal_freq1_freq2_FS48000_playDevName_CHchannelID_recDevName_CHchannelID_extracircuit.dat
% split play-side version: calDir/cal_freq1_freq2_FS48000_playDevName_CHchannelID_extracircuit.dat
% split rec-side version: calDir/cal_freq1_freq2_FS48000_recDevName_CHchannelID_extracircuit.dat
function filename = genCalFilename(freqs, fs, devSpecs, extraCircuit='')
  global dataDir;
  
  % freq1_freq2_...
  freqsPart = '';
  for i = 1:length(freqs)
    freqsPart = [freqsPart,  int2str(floor(freqs(i))), '_'];
  endfor
  
  if (length(extraCircuit) > 0)
    extraCircuit = ['_' extraCircuit];
  endif
  
  filename = ['cal_' freqsPart 'FS' int2str(fs)];
  
  % wrap single-device devSpecs
  if rows(devSpecs) == 1
    devSpecs = {devSpecs};
  endif
  for id = 1:rows(devSpecs)
    devSpec = devSpecs{id};
    filename = [filename '_' devSpec{1} '_CH' int2str(devSpec{2})];
  endfor
  
  filename = [filename extraCircuit '.dat'];
  filename = genDataPath(filename);
endfunction



%!test
%! global dataDir = '/tmp';
%! freqs = [1000; 2000];
%! fs = 48000;
%! extraCircuit = 'filter1';
%! devSpecs = { {'play8', 2}; {'rec8', 1}};
%! expected = '/tmp/cal_1000_2000_FS48000_play8_CH2_rec8_CH1_filter1.dat';
%! assert(expected, genCalFilename(freqs, fs, devSpecs, extraCircuit));
%! extraCircuit = '';
%! devSpecs = {'rec8', 1};
%! expected = '/tmp/cal_1000_2000_FS48000_rec8_CH1.dat';
%! assert(expected, genCalFilename(freqs, fs, devSpecs, extraCircuit));