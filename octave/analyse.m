function [compenReference, result] = analyse(buffer, fs, restart)
  persistent analysisBuffer = [];
  global calRec;
  global periodLength;
  
  if (restart)
    analysisBuffer = [];
  endif

  if (isempty(analysisBuffer))
    % first run
    global calFile;    
    % loading calRec
    load(calFile);
    peaks = calRec.peaks;
    printf('Peaks read from calibration file:\n');
    disp(convertPeaksToPrintable(peaks));
    measfreq = peaks(1, 1);
    periodLength = fs/measfreq;
  endif
  
  analysisBuffer = [analysisBuffer; buffer];
  
  % analysing at least 10 periods
  analysisCnt = periodLength * 10;
  if (length(analysisBuffer) < analysisCnt)
    % not enough data, run again, send more data
    compenReference = [];
    readCnt = length(buffer);
    result = 0;
    return;
  else
    % finding phase
    % NOTE - length of returned compenReference determines length of buffer read for compensation. 
    % All the figures are aligned to full periods. We must measure the phase for end of analysisBuffer 
    % because next read buffer will continue after the last sample in analysisBuffer
    %
    [ampl, phase] = measurePhase(analysisBuffer(end - analysisCnt + 1:end), fs, measfreq, false);
    % only first 10 harmonics
    refFragment = genCompenReference(peaks(1:10, :), phase, ampl, fs, periodLength);
    % size of buffer for calibration - full periods within buffer size
    periods = floor(length(buffer) / periodLength);    
    compenReference = repmat(refFragment, periods, 1);
    % finished OK
    result = 1;
  endif
endfunction