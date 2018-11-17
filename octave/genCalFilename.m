% result: calDir/cal_freq1_freq2_FS48000_device.dat
function filename = genCalFilename(freqs, fs)
  global calDir;
  global deviceName;
  
  % freq1_freq2_...
  freqsPart = '';
  for i = 1:length(freqs)
    freqsPart = [freqsPart,  int2str(floor(freqs(i))), '_'];
  endfor
  
  filename = [calDir filesep() 'cal_' freqsPart 'FS' int2str(fs) '_' deviceName '.dat'];
endfunction