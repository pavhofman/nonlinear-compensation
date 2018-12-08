    % v playback se spusti frekvence 'gen 3000'
    % v record se nacte 'meas 3000 2'
function [transfer, result] = measureTransfer(buffer, fs, transfer, restartMeasuring)
  persistent measBuffer = [];
  persistent phaseAnalysisSize = 0;
  
  % buffer was already added to measBuffer in this run
  bufferWasAdded = false;
  
  if (restartMeasuring)
    % new start - clearing the buffer
    measBuffer = [];
    % TODO - determine reasonable nb. of samples
    phaseAnalysisSize = 200;
  endif

    
  if (!bufferWasAdded)
    % buffer was not added in this run
    measBuffer = [measBuffer; buffer];
  endif
    
  if (rows(measBuffer) < phaseAnalysisSize)
    % not enough data, run again, send more data
    result = 0;
    return;
  else
    % finding phase, amplitude of the original signal
    % channel with original signal = the other channel than with transfer signal
    if (transfer.channel == 1)
      origCh = 2;
    else
      origCh = 1;
    endif

    % 'fake' fundPeaks - only freq must be precise, ampl is used only as init value for fitting, angle is ignored
    fundPeaks = [transfer.freq, 1, 0];
    peaksOrigCh = measureSingleTonePhase(measBuffer(1:phaseAnalysisSize, origCh), fs, fundPeaks, false);
    peaksTransfCh = measureSingleTonePhase(measBuffer(1:phaseAnalysisSize, transfer.channel), fs, fundPeaks, false);
    
    transfer.gain = peaksTransfCh(1, 2) / peaksOrigCh(1, 2);
    phaseShift = peaksTransfCh(1, 3) - peaksOrigCh(1, 3);
    % normalising to <-2pi, 0>
    multiples2pi = ceil(phaseShift/(2*pi));
    phaseShift -= multiples2pi * 2*pi;
    transfer.phaseShift = phaseShift;    
    % finished OK
    % clearing the buffer for next run
    measBuffer = [];
    result = 1;
    return;    
  endif
endfunction
