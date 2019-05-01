% Measures gain against genAmpl and phaseshift (against the other channel, corrected for interchannel difference) at transfer.freq of channel transfer.channel
% Stores into transfer struct
function [transfer, result] = measureTransfer(buffer, fs, transfer, genAmpl, restartMeasuring)
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
    global NOT_FINISHED_RESULT;
    result = NOT_FINISHED_RESULT;
    return;
  else
    % finding phase, amplitude of the direct + transferred signal
    % channel with direct signal = the other channel than with transfer signal
    if (transfer.channel == 1)
      directCh = 2;
    else
      directCh = 1;
    endif

    % 'fake' fundPeaks - only freq must be precise, ampl is used only as init value for fitting, angle is ignored
    fundPeaks = [transfer.freq, 1, 0];
    peaksDirectCh = measureSingleTonePhase(measBuffer(1:phaseAnalysisSize, directCh), fs, fundPeaks, false);
    peaksTransfCh = measureSingleTonePhase(measBuffer(1:phaseAnalysisSize, transfer.channel), fs, fundPeaks, false);
    
    % NOTE - transfer gain is against the generator amplitude on D side!
    transfer.gain = peaksTransfCh(1, 2) / genAmpl;
    
    % phaseshift between directCh and transfer channel for direct loopback (no filter) - soundcards are not ideal
    interChPhaseDiff = getInterChannelPhaseDiff(fs, transfer.freq, directCh, transfer.channel);

    phaseShift = peaksTransfCh(1, 3) - peaksDirectCh(1, 3) - interChPhaseDiff;
    % normalising to <-2pi, 0>
    multiples2pi = ceil(phaseShift/(2*pi));
    phaseShift -= multiples2pi * 2*pi;
    transfer.phaseShift = phaseShift;    
    % finished OK
    % clearing the buffer for next run
    measBuffer = [];
    global FINISHED_RESULT;
    result = FINISHED_RESULT;
    return;    
  endif
endfunction

% determines phase difference between soundcard channels from cal file at freq.
function phaseDiff = getInterChannelPhaseDiff(fs, freq, directCh, transferCh)
  global jointDeviceName;
  calFile = genCalFilename(freq, fs, directCh, jointDeviceName);  
  load(calFile);
  directChPhase = calRec.fundPeaks(1, 3);
  
  calFile = genCalFilename(freq, fs, transferCh, jointDeviceName);  
  load(calFile);  
  transferChPhase = calRec.fundPeaks(1, 3);
  
  phaseDiff = transferChPhase - directChPhase;
endfunction

