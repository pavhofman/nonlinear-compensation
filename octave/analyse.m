% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == 0, send more data
% if result == 1, then output:
% measuredParams(channel) = [ampl, peak]
% paramsAdvanceT - advance time of measuredParams related to the end of buffer (use t = paramsAdvanceT for starting sample of next buffer in compenReference calculation)
% fundPeaks, distortPeaks - read from calibration file corresponding to current stream freqs
function [measuredParams, paramsAdvanceT, fundPeaks, distortPeaks, freqs, result] = analyse(buffer, fs, freqs, restartAnalysis)
  persistent analysisBuffer = [];
  persistent fundPeaks = [];
  persistent distortPeaks = [];
  persistent measfreq = 0;  
  persistent periodLength = 0;
  persistent phaseAnalysisSize = 0;
  persistent calRec = struct; 
  % should reload calFile
  rereadCalFile = false;
  
  measuredParams = [];
  paramsAdvanceT = -1;
  
  % buffer was already added to analysisBuffer in this run
  bufferWasAdded = false;
  
  if (restartAnalysis)
    % new start - clearing the buffer
    analysisBuffer = [];
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
      % enough data, determine freqs, peaks are ignored (not calibration signal)
      [freqs, fundPeaks, distortPeaks] = measurePeaks(analysisBuffer, fs);
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
      fundPeaks = calRec.fundPeaks;
      distortPeaks = calRec.distortPeaks;
      printf('Distortion peaks read from calibration file %s:\n', calFile);
      disp(convertPeaksToPrintable(distortPeaks));
      
      % for now only single frequency is supported
      measfreq = fundPeaks(1, 1, 1);
      periodLength = floor(fs/measfreq);
      % phase analysis requires at least 3 periods
      phaseAnalysisSize = periodLength * 2;      
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
      measuredParams = [];
      for i = 1:columns(buffer)
        % finding phase, amplitude
        % We must measure the phase for end of analysisBuffer
        % because next read buffer will continue after the last sample in analysisBuffer
        fundAmpl = fundPeaks(1, 2, i);
        %id = tic();
        [ampl, phaseShift] = measurePhaseCurvefit(analysisBuffer(end - phaseAnalysisSize + 1:end, i), fs, measfreq, fundAmpl, false);
        %disp(toc(id));
        measuredParams(i, 1) = ampl;
        measuredParams(i, 2) = phaseShift;
      endfor
      % advance time of measuredParams relative to the end of buffer - the generated compensation reference must be shifted by this to fit beginning of the next buffer
      paramsAdvanceT = phaseAnalysisSize/fs;
      % finished OK
      % clearing the buffer for next run
      analysisBuffer = [];
      result = 1;
      return;
    endif
  endif
endfunction
