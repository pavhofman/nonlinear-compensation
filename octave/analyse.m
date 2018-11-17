% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == 0, send more data
% if result == 1, compenReference contains generated compensation samples for all channels in buffer
function [compenReference, freqs, result] = analyse(buffer, fs, freqs, restartAnalysis)
  persistent analysisBuffer = [];
  persistent peaks = [];
  persistent measfreq = 0;
  persistent periodLength = 0;
  persistent phaseAnalysisSize = 0;
  persistent calRec = struct; 
  % should reload calFile
  rereadCalFile = false;
  
  
  % buffer was already added to analysisBuffer in this run
  bufferWasAdded = false;
  
  compenReference = [];
  
  if (restartAnalysis)
    % new start - clearing the buffer
    analysisBuffer = [];
    compenReference = [];
    rereadCalFile = true;
  endif
  
  if (freqs(1) < 0)
    % we must determine current freqs first
    printf('Unknown freqs for analysis, must determine first\n');
    analysisBuffer = [analysisBuffer; buffer];
    bufferWasAdded = true;

    % frequency analysis requires 1 second
    freqAnalysisSize = fs;

    if (rows(analysisBuffer) < freqAnalysisSize)
      % not enough data, run again, send more data
      result = 0;
      return;
    else
      % enough data, determine frequencies
      freqs = determineFundamentalFreqs(analysisBuffer, fs);
      % continue with phase analysis
      rereadCalFile = true;
    endif
  endif
      
  if (freqs(1) > 0)
    if (restartAnalysis || rereadCalFile)
      % re-reading cal file
      calFile = genCalFilename(freqs, fs);
      % loading calRec, initialising persistent vars
      load(calFile);
      peaks = calRec.peaks;
      printf('Peaks read from calibration file %s:\n', calFile);
      disp(convertPeaksToPrintable(peaks));
      measfreq = peaks(1, 1, 1);
      periodLength = fs/measfreq;
      % phase analysis requires at least 10 periods
      phaseAnalysisSize = periodLength * 10;      
    endif
    
    if (!bufferWasAdded)
      % buffer was not added in this run by frequency analysis
      analysisBuffer = [analysisBuffer; buffer];
    endif
    
    if (rows(analysisBuffer) < phaseAnalysisSize)
      % not enough data, run again, send more data
      result = 0;
      return;
    else
      % size of buffer for calibration - full periods within buffer size
      periods = floor(rows(buffer) / periodLength);    
      compenReference = [];
      for i = 1:columns(buffer)
        % finding phase
        % All the figures are aligned to full periods. We must measure the phase for end of analysisBuffer 
        % because next read buffer will continue after the last sample in analysisBuffer
        %
        [ampl, phase] = measurePhase(analysisBuffer(end - phaseAnalysisSize + 1:end, i), fs, measfreq, false);
        % only first 10 harmonics
        refFragment = genCompenReference(peaks(1:10, :, i), phase, ampl, fs, periodLength);
        rowCompenReference = repmat(refFragment, periods, 1);
        compenReference = [compenReference, rowCompenReference];
      endfor
      % finished OK
      % clearing the buffer for next run
      analysisBuffer = [];
      result = 1;
      return;
    endif
  endif
endfunction

% Determining fundamental frequencies in buffer. Returns array of frequencies
function freqs = determineFundamentalFreqs(buffer, fs)
  peaks = getHarmonics(buffer, fs);
  printf('Determined fundamental freqs:\n');
  % for now only single frequency
  freqs = peaks(1, 1, 1);
  disp(freqs);
  printf('\n');
endfunction