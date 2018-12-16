% result: calDir/cal_freq1_freq2_FS48000_deviceName_extracircuit.dat
function filename = genCalFilename(freqs, fs, deviceName, extraCircuit='')
  global varDir;
  
  % freq1_freq2_...
  freqsPart = '';
  for i = 1:length(freqs)
    freqsPart = [freqsPart,  int2str(floor(freqs(i))), '_'];
  endfor
  
  if (length(extraCircuit) > 0)
    extraCircuit = ['_' extraCircuit];
  endif
  
  filename = [varDir filesep() 'cal_' freqsPart 'FS' int2str(fs) '_' deviceName extraCircuit '.dat'];
endfunction