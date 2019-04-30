% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == NOT_FINISHED_RESULT, send more data
% if result == FINISHED_RESULT, then output:
% measuredPeaks - measured fundamental peaks
% paramsAdvanceT - advance time of measuredParams related to the end of buffer (use t = paramsAdvanceT for starting sample of next buffer in compenReference calculation)
% fundLevels, distortPeaks - read from calibration file corresponding to current stream freqs
%
% fundLevels: since distortPeaks are ALWAYS zero-time based, i.e. phase = 0 for all fundamental frequencies, fundLevels only contains frequency and level, no phases
function [measuredPeaks, paramsAdvanceT, fundLevels, distortPeaks, result, msg] = analyse(buffer, fs, compRequest, reloadCalFiles)
  persistent analysisBuffer = [];
  persistent channelCnt = columns(buffer);
  
  global NOT_FINISHED_RESULT;
  global FINISHED_RESULT;
  global FAILED_RESULT;
  
  msg = '';

  measuredPeaks = cell(channelCnt, 1);
  fundLevels = cell(channelCnt, 1);
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
    % enough data, measure fundLevels, distortPeaks are ignored (not calibration signal)
    measuredPeaks = getHarmonics(analysisBuffer, fs, false);
    
    hasAnyChannelPeaks = false;
    % each channel handled separately
    global MIN_DISTORT_LEVEL;
    for channelID = 1:channelCnt
      measuredPeaksCh = measuredPeaks{channelID};
      if hasAnyPeak(measuredPeaksCh)
        hasAnyChannelPeaks = true;
        writeLog('TRACE', 'Found fundPeaks for channel ID %d', channelID);
        if isstruct(compRequest)
          [fundLevelsCh, distortPeaksCh, calFile] = genCompensationPeaks(measuredPeaksCh, fs, compRequest, channelID, channelCnt, reloadCalFiles);
          % removing rows with ampl < MIN_DISTORT_LEVEL
          if ~isempty(distortPeaksCh)
            distortPeaksCh(distortPeaksCh(:, 2) < MIN_DISTORT_LEVEL, :) = [];
          endif
        else
          % not generating compen peaks
          fundLevelsCh = [];
          distortPeaksCh = [];
          calFile = '';
        endif
      else
        writeLog('DEBUG', 'Did not find any fundaments, channel ID %d PASSING', channelID);
        % not generating compen peaks
        fundLevelsCh = [];
        distortPeaksCh = [];
        calFile = '';
      endif        
      fundLevels{channelID} = fundLevelsCh;
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


function [fundLevelsCh, distortPeaksCh, calFile] = genCompensationPeaks(measuredPeaksCh, fs, compRequest, channelID, channelCnt, reloadCalFiles);
  
  persistent distortFreqs = cell(channelCnt, 1);
  persistent complAllPeaks = cell(channelCnt, 1);
  persistent calFiles = cell(channelCnt, 1);
  
  persistent prevFreqs = cell(channelCnt, 1);  
  persistent sameFreqsCounter = zeros(channelCnt, 1);
  % how many cycles freqs must be same until declared stable - avoid artefacts caused by freqs change within the cycle
  persistent SAME_FREQS_ROUNDS = 2;
    
  % default values
  fundLevelsCh = [];
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
    %writeLog('DEBUG', 'sameFreqsCounter(%d): %d', channelID, sameFreqsCounter(channelID));
    if sameFreqsCounter(channelID) >= SAME_FREQS_ROUNDS
      if sameFreqsCounter(channelID) == SAME_FREQS_ROUNDS || reloadCalFiles
        % changed incoming frequency, has been stable for SAME_FREQS_ROUNDS, load from calfile (if exists)
        [distortFreqsCh, complAllPeaksCh, calFile] = loadPeaks(freqsCh, fs, channelID, compRequest);
        % beware - interpl used for interpolation does not work with NA values. We have to interpolate/fill the missing values here
        if find(isna(complAllPeaksCh))
          complAllPeaksCh = fillMissingCalPeaks(complAllPeaksCh);
        endif
        % storing to persistent vars
        distortFreqs{channelID} = distortFreqsCh;
        complAllPeaks{channelID} = complAllPeaksCh;
        calFiles{channelID} = calFile;
      endif
    
      % interpolating
      if !isempty(complAllPeaks{channelID})
        % interpolate to current measured level
        [fundLevelsCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs{channelID}, complAllPeaks{channelID});
        calFile = calFiles{channelID};
      endif
    endif
  endif
endfunction  

function [distortFreqsCh, complAllPeaksCh, calFile] = loadPeaks(freqs, fs, channelID, compRequest)
  % values for no signal/no calfile
  distortFreqsCh = [];
  complAllPeaksCh = [];
  
  % re-reading cal file with one channel calib data
  calFile = genCalFilename(freqs, fs, compRequest.compType, compRequest.playChannelID, channelID, compRequest.extraCircuit);
  if (exist(calFile, 'file'))
    % loading calRec, initialising persistent vars
    load(calFile);
    distortFreqsCh = calRec.distortFreqs;
    complAllPeaksCh = calRec.peaks;
    writeLog('INFO', 'Distortion peaks for channel ID %d read from calibration file %s', channelID, calFile);
  else
    writeLog('WARN', 'Did not find calib file %s, channel ID %d PASSING', calFile, channelID);
    calFile = '';    
  endif
endfunction


function [fundLevelsCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs, complAllPeaks)
  % complAllPeaks: time, fundPhaseDiff1, fundPhaseDiff2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
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
  % since currentPeaksCh are already interpolated to current level, fundLevels = measuredPeaksCh (without phase info)
  fundLevelsCh = measuredPeaksCh(:, 1:2);
endfunction