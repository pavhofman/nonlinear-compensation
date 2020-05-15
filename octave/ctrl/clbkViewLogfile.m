% sending calibration command to rec side + showing lastLines in the plots
function clbkViewLogfile(src, data, logName)
  global logDir;

  open(sprintf("%s%s%s.log", logDir, filesep(), logName));
endfunction
