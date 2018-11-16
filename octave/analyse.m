function [compenReference, result] = analyse(buffer, fs, restart)
  persistent analysisBuffer = [];
  persistent peaks = [];
  persistent measfreq = 0;
  persistent periodLength = 0;
  persistent calRec = struct;
  
  
  if (restart)
    analysisBuffer = [];
  endif

  if (isempty(analysisBuffer))
    % first run
    global calFile;
    % loading calRec, initialising persistent vars
    load(calFile);
    peaks = calRec.peaks;
    printf('Peaks read from calibration file:\n');
    disp(convertPeaksToPrintable(peaks));
    measfreq = peaks(1, 1, 1);
    periodLength = fs/measfreq;
  endif
  
  analysisBuffer = [analysisBuffer; buffer];
  
  % analysing at least 10 periods
  analysisCnt = periodLength * 10;
  if (rows(analysisBuffer) < analysisCnt)
    % not enough data, run again, send more data
    compenReference = [];
    readCnt = rows(buffer);
    result = 0;
    return;
  else
    % size of buffer for calibration - full periods within buffer size
    periods = floor(rows(buffer) / periodLength);    
    compenReference = [];
    for i = 1:columns(buffer)
      % finding phase
      % NOTE - length of returned compenReference determines length of buffer read for compensation. 
      % All the figures are aligned to full periods. We must measure the phase for end of analysisBuffer 
      % because next read buffer will continue after the last sample in analysisBuffer
      %
      [ampl, phase] = measurePhase(analysisBuffer(end - analysisCnt + 1:end, i), fs, measfreq, false);
      % only first 10 harmonics
      refFragment = genCompenReference(peaks(1:10, :, i), phase, ampl, fs, periodLength);
      rowCompenReference = repmat(refFragment, periods, 1);
      compenReference = [compenReference, rowCompenReference];
    endfor
    % finished OK
    result = 1;
  endif
endfunction