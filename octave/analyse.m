% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == NOT_FINISHED_RESULT, send more data
% if result == FINISHED_RESULT, then output:
% measuredPeaks - measured fundamental peaks
% paramsAdvanceT - advance time of measuredParams related to the end of buffer (use t = paramsAdvanceT for starting sample of next buffer in compenReference calculation)
% fundPeaks, distortPeaks - read from calibration file corresponding to current stream freqs
function [measuredPeaks, paramsAdvanceT, fundPeaks, distortPeaks, result] = analyse(buffer, fs, calDeviceName, extraCircuit, restartAnalysis)

  persistent analysisBuffer = [];
  persistent channelCnt = columns(buffer);
  persistent fundPeaks = cell(channelCnt);
  persistent distortPeaks = cell(channelCnt);
  
  persistent distortFreqs = cell(channelCnt);
  persistent complAllPeaks = cell(channelCnt);
  
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
      measuredPeaksCh = measuredPeaks{channelID};
    
      freqs = getFreqs(measuredPeaksCh);
      % check if new and stable
      if isChangedAndStable(freqs, channelID, channelCnt, clearFreqHistory) || restartAnalysis
        % changed incoming frequency
        [distortFreqsCh, complAllPeaksCh] = loadPeaks(measuredPeaksCh, freqs, fs, channelID, calDeviceName, extraCircuit);
        % beware - interpl used for interpolation does not work with NA values. We have to interpolate/fill the missing values here
        if find(isna(complAllPeaksCh))
          complAllPeaksCh = fillMissingPeaks(complAllPeaksCh);
        endif
        % storing to persistent vars
        distortFreqs{channelID} = distortFreqsCh;
        complAllPeaks{channelID} = complAllPeaksCh;
        
      endif
      if !isempty(complAllPeaks{channelID})
        % interpolate to current measured level
        [fundPeaksCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs{channelID}, complAllPeaks{channelID});
      else          
        % no signal  
        % zero peaks
        fundPeaksCh = [];
        distortPeaksCh = [];
      endif
      fundPeaks{channelID} = fundPeaksCh;
      distortPeaks{channelID} = distortPeaksCh;
    endfor
    
    clearFreqHistory = false;
    % measuredPeaks are calculated for time at start of analysisBuffer
    % but compensation will work on the current buffer
    % advance time of measuredPeaks relative to the start of buffer which is located at the end of analysisBuffer [analysisBuffer [ buffer]]
    paramsAdvanceT = (rows(analysisBuffer) - rows(buffer))/fs;    
    % finished OK
    result = FINISHED_RESULT;
    return;
  endif
endfunction



function [distortFreqsCh, complAllPeaksCh] = loadPeaks(measuredPeaksCh, freqs, fs, channelID, calDeviceName, extraCircuit)
  % values for no signal/no calfile
  distortFreqsCh = [];
  complAllPeaksCh = [];
  
  if (hasAnyPeak(measuredPeaksCh))
    % re-reading cal file with one channel calib data
    calFile = genCalFilename(freqs, fs, channelID, calDeviceName, extraCircuit);
    if (exist(calFile, 'file'))
      % loading calRec, initialising persistent vars
      load(calFile);
      distortFreqsCh = calRec.distortFreqs;
      complAllPeaksCh = calRec.distortPeaks;
      printf('Distortion peaks for channel ID %d read from calibration file %s\n', channelID, calFile);
    else
      printf('Did not find calib file %s, channel ID %d PASSING\n', calFile, channelID);
    endif
  else
    printf('Did not find any fundaments, channel ID %d PASSING\n', channelID);
  endif
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


function [fundPeaksCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs, complAllPeaks)
  % complAllPeaks: time, origFundPhase1, origFundPhase2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  % WARN: ALL peaks must be known (no NA values!)
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
  persistent PEAKS_START_IDX = 6; 

  allPeaks = complAllPeaks(:, PEAKS_START_IDX:end);
 
  % levels = AMPL_IDX column
  levels = complAllPeaks(:, AMPL_IDX);
  
  % amplitude of first fundamental
  currentLevel = measuredPeaksCh(1, 2);  
  % interpolate, non-complex output!!!
  
  distortPeaksCh = [];
  % interp1 is slow (10ms in internal ppval()), run only once for all freqs
  peaksAtLevel = interp1(levels, allPeaks , currentLevel, 'linear', 'extrap');
  peaksAtLevel = transpose(peaksAtLevel);
  distortPeaksCh = [transpose(distortFreqs), abs(peaksAtLevel), angle(peaksAtLevel)];
  % since currentPeaksCh are already interpolated to current level, fundPeaks = measuredPeaksCh with zero phase
  fundPeaksCh = measuredPeaksCh;
  fundPeaksCh(:, 3) = 0;
endfunction

% interpolate all missing (NA) distortion peaks
% replacement for matlab's fillmissing
function complAllPeaks = fillMissingPeaks(complAllPeaks)
  % complAllPeaks: time, origFundPhase1, origFundPhase2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
 
  % levels = AMPL_IDX column
  levels = complAllPeaks(:, AMPL_IDX);
  
  % only distort peaks can be missing, it is safe to search whole complAllPeaks
  missingPeaksIDs = isnan(complAllPeaks);
  
  % interpolate for each frequency with missing values
  % indices of columns with MISSING value
  colIDs = find(any(missingPeaksIDs));
  for colID = colIDs
    missingPeaksIDsInCol = missingPeaksIDs(:, colID);
    knownLevels = levels(~missingPeaksIDsInCol);
    missingLevels = levels(missingPeaksIDsInCol);
    knownPeaks = complAllPeaks(~missingPeaksIDsInCol, colID);
    peaksAtLevels = interp1(knownLevels, knownPeaks, missingLevels, 'linear', 'extrap');
    % insert interpolated values into complAllPeaks
    complAllPeaks(find(missingPeaksIDsInCol), colID) = peaksAtLevels;
  endfor
endfunction