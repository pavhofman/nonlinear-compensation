% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == NOT_FINISHED_RESULT, send more data
% if result == FINISHED_RESULT, then output:
% measuredPeaks - measured fundamental peaks
% paramsAdvanceT - advance time of measuredParams related to the end of buffer (use t = paramsAdvanceT for starting sample of next buffer in compenReference calculation)
% fundPeaks, distortPeaks - read from calibration file corresponding to current stream freqs
function [measuredPeaks, paramsAdvanceT, fundPeaks, distortPeaks, result, msg] = analyse(buffer, fs, calDeviceName, extraCircuit, shouldGenCompenPeaks, reloadCalFiles)
  persistent analysisBuffer = [];
  persistent channelCnt = columns(buffer);
  
  global NOT_FINISHED_RESULT;
  global FINISHED_RESULT;
  global FAILED_RESULT;
  
  msg = '';

  measuredPeaks = cell(channelCnt, 1);
  fundPeaks = cell(channelCnt, 1);
  distortPeaks = cell(channelCnt, 1);

  paramsAdvanceT = -1;
  
  analysisBuffer = [analysisBuffer; buffer];

  % frequency analysis requires 1 second
  freqAnalysisSize = fs;

  if (rows(analysisBuffer) < freqAnalysisSize)
    % not enough data, run again, send more data      
    result = NOT_FINISHED_RESULT;
    return;
  else
    % purging old samples from analysis buffer to cut analysisBuffer to freqAnalysisSize     
    analysisBuffer = analysisBuffer(rows(analysisBuffer) - freqAnalysisSize + 1: end, :);
    % enough data, measure fundPeaks, distortPeaks are ignored (not calibration signal)
    measuredPeaks = getHarmonics(analysisBuffer, fs, false);
    
    hasAnyChannelPeaks = false;
    % each channel handled separately
    for channelID = 1:channelCnt
      measuredPeaksCh = measuredPeaks{channelID};
      if hasAnyPeak(measuredPeaksCh)
        hasAnyChannelPeaks = true;
        if shouldGenCompenPeaks
          [fundPeaksCh, distortPeaksCh, calFile] = genCompensationPeaks(measuredPeaksCh, fs, calDeviceName, extraCircuit, channelID, channelCnt, reloadCalFiles);
        else
          % not generating compen peaks
          fundPeaksCh = [];
          distortPeaksCh = [];
          calFile = '';
        endif
      else
        printf('Did not find any fundaments, channel ID %d PASSING\n', channelID);
        % not generating compen peaks
        fundPeaksCh = [];
        distortPeaksCh = [];
        calFile = '';
      endif        
      fundPeaks{channelID} = fundPeaksCh;
      distortPeaks{channelID} = distortPeaksCh;
      global compenCalFiles;
      compenCalFiles{channelID} = calFile;
    endfor
    
    if hasAnyChannelPeaks
      % one channel is enough for OK
      result = FINISHED_RESULT;
    else
      msg = 'No fundamentals in any channel found';
      result = FAILED_RESULT;
    endif

    % measuredPeaks are calculated for time at start of analysisBuffer
    % but compensation will work on the current buffer
    % advance time of measuredPeaks relative to the start of buffer which is located at the end of analysisBuffer [analysisBuffer [ buffer]]
    paramsAdvanceT = (rows(analysisBuffer) - rows(buffer))/fs;    
    % finished OK    
    return;
  endif
endfunction


function [fundPeaksCh, distortPeaksCh, calFile] = genCompensationPeaks(measuredPeaksCh, fs, calDeviceName, extraCircuit, channelID, channelCnt, reloadCalFiles);
  
  persistent distortFreqs = cell(channelCnt, 1);
  persistent complAllPeaks = cell(channelCnt, 1);
  persistent calFiles = cell(channelCnt, 1);
  
  persistent prevFreqs = cell(channelCnt, 1);  
  persistent sameFreqsCounter = zeros(channelCnt, 1);
  % how many cycles freqs must be same until declared stable - avoid artefacts caused by freqs change within the cycle
  persistent SAME_FREQS_ROUNDS = 2;
  
  % default values
  fundPeaksCh = [];
  distortPeaksCh = [];
  calFile = '';

  freqsCh = getFreqs(measuredPeaksCh);
        
  % check if new and stable
  areSame = isequal(freqsCh, prevFreqs{channelID});
  % remember for next round
  prevFreqs{channelID} = freqsCh;
  if ~areSame
    % are different
    % reset the counter
    sameFreqsCounter(channelID) = 0;
    % next run
    return;
  else
    % same freqs from previous run, can continue
    sameFreqsCounter(channelID) += 1;
    
    if sameFreqsCounter(channelID) >= SAME_FREQS_ROUNDS
      if sameFreqsCounter(channelID) == SAME_FREQS_ROUNDS || reloadCalFiles
        % changed incoming frequency, has been stable for SAME_FREQS_ROUNDS, load from calfile (if exists)
        [distortFreqsCh, complAllPeaksCh, calFile] = loadPeaks(freqsCh, fs, channelID, calDeviceName, extraCircuit);
        % beware - interpl used for interpolation does not work with NA values. We have to interpolate/fill the missing values here
        if find(isna(complAllPeaksCh))
          complAllPeaksCh = fillMissingPeaks(complAllPeaksCh);
        endif
        % storing to persistent vars
        distortFreqs{channelID} = distortFreqsCh;
        complAllPeaks{channelID} = complAllPeaksCh;
        calFiles{channelID} = calFile;
      endif
    
      % interpolating
      if !isempty(complAllPeaks{channelID})
        % interpolate to current measured level
        [fundPeaksCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs{channelID}, complAllPeaks{channelID});
        calFile = calFiles{channelID};
      endif
    endif
  endif
endfunction  

function [distortFreqsCh, complAllPeaksCh, calFile] = loadPeaks(freqs, fs, channelID, calDeviceName, extraCircuit)
  % values for no signal/no calfile
  distortFreqsCh = [];
  complAllPeaksCh = [];
  
  % re-reading cal file with one channel calib data
  calFile = genCalFilename(freqs, fs, channelID, calDeviceName, extraCircuit);
  if (exist(calFile, 'file'))
    % loading calRec, initialising persistent vars
    load(calFile);
    distortFreqsCh = calRec.distortFreqs;
    complAllPeaksCh = calRec.peaks;
    printf('Distortion peaks for channel ID %d read from calibration file %s\n', channelID, calFile);
  else
    printf('Did not find calib file %s, channel ID %d PASSING\n', calFile, channelID);
    calFile = '';    
  endif
endfunction


function [fundPeaksCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs, complAllPeaks)
  % complAllPeaks: time, origFundPhase1, origFundPhase2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  % WARN: ALL peaks must be known (no NA values!)
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
  persistent PEAKS_START_IDX = 6; 
  distortPeaksCh = [];
  
  allDPeaksC = complAllPeaks(:, PEAKS_START_IDX:end);
  if ~isempty(allDPeaksC) 
    % the actual interpolation
    
    % levels = AMPL_IDX column
    levels = complAllPeaks(:, AMPL_IDX);
    
    % amplitude of first fundamental
    currentLevel = measuredPeaksCh(1, 2);  
    % interpolate, non-complex output!!!
    

    % interp1 is slow (10ms in internal ppval()), run only once for all freqs
    peaksAtLevel = interp1(levels, allDPeaksC , currentLevel, 'linear', 'extrap');
    peaksAtLevel = transpose(peaksAtLevel);
    distortPeaksCh = [transpose(distortFreqs), abs(peaksAtLevel), angle(peaksAtLevel)];
  endif
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