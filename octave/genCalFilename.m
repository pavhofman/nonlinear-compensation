% result: calDir/cal_freq1_freq2_device.dat
function filename = genCalFilename(freqs)
  global calDir;
  global deviceName;
  
  % freq1_freq2_...
  freqsPart = '';
  for i = 1:length(freqs)
    freqsPart = [freqsPart,  int2str(floor(freqs(i))), '_'];
  endfor
  
  filename = [calDir filesep() 'cal_' freqsPart deviceName '.dat'];
endfunction