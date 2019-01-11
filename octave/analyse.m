% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == NOT_FINISHED_RESULT, send more data
% if result == FINISHED_RESULT, then output:
% measuredPeaks - measured fundamental peaks
% paramsAdvanceT - advance time of measuredParams related to the end of buffer (use t = paramsAdvanceT for starting sample of next buffer in compenReference calculation)
% fundPeaks, distortPeaks - read from calibration file corresponding to current stream freqs
function [measuredPeaks, paramsAdvanceT, fundPeaks, distortPeaks, result] = analyse(buffer, fs, calDeviceName, extraCircuit, restartAnalysis)
  persistent analysisBuffer = [];
  persistent channelCnt = columns(buffer);
  persistent fundPeaks = zeros(getMaxFundPeaksCnt(), 3, channelCnt);
  persistent distortPeaks = zeros(getMaxDistortPeaksCnt(), 3, channelCnt);
  
  persistent clearFreqHistory = true;
  
  global NOT_FINISHED_RESULT;
  global FINISHED_RESULT;

  measuredPeaks = [];
  paramsAdvanceT = -1;
  
  if (restartAnalysis)
    % new start - clearing the buffer
    analysisBuffer = [];
  endif

  analysisBuffer = [analysisBuffer; buffer];

  % frequency analysis requires 1 second
  freqAnalysisSize = fs;

  if (rows(analysisBuffer) < freqAnalysisSize)
    % not enough data, run again, send more data      
    result = NOT_FINISHED_RESULT;
    clearFreqHistory = true;
    return;
  else
    % purging old samples from analysis buffer to cut analysisBuffer to freqAnalysisSize     
    analysisBuffer = analysisBuffer(rows(analysisBuffer) - freqAnalysisSize + 1: end, :);
    % enough data, measure fundPeaks, distortPeaks are ignored (not calibration signal)
    measuredPeaks = getHarmonics(analysisBuffer, fs, false);
    
    % each channel handled separately
    for channelID = 1:channelCnt
      measuredPeaksCh = measuredPeaks(:,:,channelID);
    
      freqs = getFreqs(measuredPeaksCh);
      % check if new and stable
      if isChangedAndStable(freqs, channelID, channelCnt, clearFreqHistory) || restartAnalysis
        % changed incoming frequency
        [fundPeaksCh, distortPeaksCh] = determinePeaks(measuredPeaksCh, freqs, fs, channelID, calDeviceName, extraCircuit);
        fundPeaks(:, :, channelID) = fundPeaksCh;
        distortPeaks(:, :, channelID) = distortPeaksCh;        
      endif
    endfor
    
    clearFreqHistory = false;
    % advance time of measuredParams relative to the end of buffer - the generated compensation reference must be shifted by this to fit beginning of the next buffer        
    paramsAdvanceT = rows(analysisBuffer)/fs;    
    % finished OK
    result = FINISHED_RESULT;
    return;
  endif
endfunction



function [fundPeaksCh, distortPeaksCh] = determinePeaks(measuredPeaksCh, freqs, fs, channelID, calDeviceName, extraCircuit)
    %consts
  persistent maxFundPeaksCnt = getMaxFundPeaksCnt();
  persistent maxDistortPeaksCnt = getMaxDistortPeaksCnt();
  
  if (hasAnyPeak(measuredPeaksCh))
    % re-reading cal file with one channel calib data
    calFile = genCalFilename(freqs, fs, channelID, calDeviceName, extraCircuit);
    if (exist(calFile, 'file'))
      % loading calRec, initialising persistent vars
      load(calFile);
      fundPeaksCh = calRec.fundPeaks;
      distortPeaksCh = calRec.distortPeaks;
      printf('Distortion peaks for channel ID %d read from calibration file %s\n', channelID, calFile);
      %disp(convertPeaksToPrintable(distortPeaksCh));
      % finished
      return;
    else
      printf('Did not find calib file %s, channel ID %d PASSING\n', calFile, channelID);
    endif
  else
    printf('Did not find any fundaments, channel ID %d PASSING\n', channelID);
  endif
  
  % zero peaks
  fundPeaksCh = zeros(maxFundPeaksCnt, 3);
  distortPeaksCh = zeros(maxDistortPeaksCnt, 3);
endfunction



function isChanged = isChangedAndStable(newFreqs, channelID, channelCnt, clearFreqHistory)
  % const
  % how many cycles freqs must be same until declared stable - avoid artefacts caused by freqs change within the cycle
  persistent EQUAL_CYCLES = 2;
  % history of last (EQUAL_CYCLES + 1) freqs, latest last
  persistent freqsHistories = initHistories(channelCnt);
  
  if clearFreqHistory
    freqsHistories = initHistories(channelCnt);
  endif
  
  freqsHistory = freqsHistories{channelID};
  % append  newFreqs at the end
  freqsHistory = [freqsHistory; newFreqs];
  
  if rows(freqsHistory) == 1
    % first run, certainly changed
    isChanged = true;
  elseif rows(freqsHistory) < (EQUAL_CYCLES + 1)
    % not enough rows to decide -> no change
    isChanged = false;
  else
    if rows(freqsHistory) > (EQUAL_CYCLES + 1)
      % purge the oldest rows from beginning, keep (EQUAL_CYCLES + 1) rows
      freqsHistory = freqsHistory(2:end, :);
    endif
    
    % isChanged IF last EQUAL_CYCLES rows are same AND different than the first one
    oldFreqs = freqsHistory(1, :);
    newFreqsRows = freqsHistory(2:end, :);
    % all newFreqsRows must be same
    newFreqsRowsEqual = nnz(diff(newFreqsRows, 1)) == 0;
    % last EQUAL_CYCLES same, previous different from newFreqs
    isChanged = newFreqsRowsEqual && !isequal(oldFreqs, newFreqs);
  endif
  % store updated freqsHistory
  freqsHistories{channelID} = freqsHistory;  
endfunction

function histories = initHistories(channelCnt)
  histories = {};
  for channelID = 1:channelCnt
    histories{channelID} = [];
  endfor
endfunction
