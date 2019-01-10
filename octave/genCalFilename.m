% result: calDir/cal_freq1_freq2_FS48000_CHchannelID_deviceName_extracircuit.dat
function filename = genCalFilename(freqs, fs, channelID, deviceName, extraCircuit='')
  global dataDir;
  
  % freq1_freq2_...
  freqsPart = '';
  for i = 1:length(freqs)
    freqsPart = [freqsPart,  int2str(floor(freqs(i))), '_'];
  endfor
  
  if (length(extraCircuit) > 0)
    extraCircuit = ['_' extraCircuit];
  endif
  
  filename = genDataPath(['cal_' freqsPart 'FS' int2str(fs) '_CH' int2str(channelID) '_' deviceName extraCircuit '.dat']);
endfunction