% analysis incoming data. If freqs unknown (< 0), determines freqs in buffer data first.
% if result == NOT_FINISHED_RESULT, send more data
% if result == FINISHED_RESULT, then output:
% measuredPeaks - measured fundamental peaks
% advanceTs - advance time of measuredParams related to the end of buffer (use t = paramsAdvanceT for starting sample of next buffer in compenReference calculation)
%             cell array - element for each active channel
% fundLevels, distortPeaks - read from calibration file corresponding to current stream freqs
%
% fundLevels: since distortPeaks are ALWAYS zero-time based, i.e. phase = 0 for all fundamental frequencies, fundLevels only contains frequency and level, no phases
function [measuredPeaks, advanceTs, fundLevels, distortPeaks, result, msg] = analyse(buffer, fs, compRequest, chMode, reloadCalFiles, restart, nonInteger)
  persistent analysisBuffer = [];
    if (restart)
      % resetting all relevant persistent vars
      analysisBuffer = [];
      % TODO - persistent vars in genCompensationPeaks should be cleared too!
    end


  channelCnt = columns(buffer);
  
  global NOT_FINISHED_RESULT;
  global FINISHED_RESULT;
  global FAILED_RESULT;
  
  msg = '';

  measuredPeaks = cell(channelCnt, 1);
  fundLevels = cell(channelCnt, 1);
  distortPeaks = cell(channelCnt, 1);

  advanceTs = cell(channelCnt, 1);
  
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
    measuredPeaks = getHarmonics(fs, analysisBuffer, fs, false);
    activeChIDs = getActiveChannelIDs(chMode, channelCnt);

    % measuredPeaks are calculated for time at start of analysisBuffer
    % but compensation will work on the current buffer
    % advance time of measuredPeaks relative to the start of buffer which is located at the end of analysisBuffer [analysisBuffer [ buffer]]
    for channelID = activeChIDs
      advanceTs{channelID} = (rows(analysisBuffer) - rows(buffer))/fs;
    end

    if nonInteger
      for channelID = activeChIDs
        measuredPeaksCh = measuredPeaks{channelID};
        peaksCnt = rows(measuredPeaksCh);
        if peaksCnt == 1 || peaksCnt == 2
          % TODO - really lower limit of 50Hz min?
          if (min(measuredPeaksCh(:, 1) > 50))
            if peaksCnt == 1
              measuredPeaksCh = findOneTonePeaks(measuredPeaksCh, analysisBuffer(:, channelID), fs);
            else
              measuredPeaksCh = findTwoTonePeaks(measuredPeaksCh, analysisBuffer(:, channelID), fs);
            end
            measuredPeaks{channelID} = measuredPeaksCh;
          end
        end
      end
    end

    hasAnyChannelPeaks = false;
    % each channel handled separately
    global MIN_DISTORT_LEVEL;
    for channelID = getActiveChannelIDs(chMode, channelCnt)      
      measuredPeaksCh = measuredPeaks{channelID};
      if hasAnyPeak(measuredPeaksCh)
        hasAnyChannelPeaks = true;
        writeLog('TRACE', 'Found fundPeaks for channel ID %d', channelID);
        if isstruct(compRequest)
          [fundLevelsCh, distortPeaksCh, calFile] = genCompensationPeaks(measuredPeaksCh, fs, compRequest, channelID, chMode, channelCnt, reloadCalFiles);
          % removing rows with ampl < MIN_DISTORT_LEVEL
          if ~isempty(distortPeaksCh)
            distortPeaksCh(distortPeaksCh(:, 2) < MIN_DISTORT_LEVEL, :) = [];
          end
        else
          % not generating compen peaks
          fundLevelsCh = [];
          distortPeaksCh = [];
          calFile = '';
        end
      else
        writeLog('DEBUG', 'Did not find any fundaments, channel ID %d PASSING', channelID);
        % not generating compen peaks
        fundLevelsCh = [];
        distortPeaksCh = [];
        calFile = '';
      end
      fundLevels{channelID} = fundLevelsCh;
      distortPeaks{channelID} = distortPeaksCh;
      global compenCalFiles;
      compenCalFiles{channelID} = calFile;
    end
    
    if hasAnyChannelPeaks
      % one channel is enough for OK
      result = FINISHED_RESULT;
    else
      msg = 'No fundamentals in any channel found';
      result = FAILED_RESULT;
    end
    % finished OK
    return;
  end
end

function measuredPeaksCh = findOneTonePeaks(measuredPeaksCh, analysisBufferCh, fs)
  persistent PI2 = 2 * pi;
  % fitting function
  persistent f = @(p, t) p(2) * cos(PI2 * p(1) * t + p(3));
  % partial derivatives
  persistent fDfdp = @(p, t) [- PI2 * p(2) * t .* sin(PI2 * p(1) * t + p(3)) , cos(PI2 * p(1) * t + p(3)),  - p(2) * sin(PI2 * p(1) * t + p(3))];  
  persistent settings = optimset ('dfdp', fDfdp);

  measFreq = measuredPeaksCh(1, 1);
  measAmpl = measuredPeaksCh(1, 2);
  measPhase = measuredPeaksCh(1, 3);

  periods = 50;
  % indep must be row vector
  t = transpose(0 : 1/fs : periods * 1/measFreq);
  
  samplesY = analysisBufferCh(1:length(t));
  init = [measFreq; measAmpl; measPhase];
    
  [p, model_values, cvg, outp] = nonlin_curvefit(f, init, t, samplesY, settings);
  if p(1) ~= measFreq
    % non-integer fundamental freq found
    [ampl, phaseShift] = fixMeasuredAmplPhase(p(2), p(3));
    measuredPeaksCh = [p(1), ampl, phaseShift];
  end
end

function measuredPeaksCh = findTwoTonePeaks(measuredPeaksCh, analysisBufferCh, fs)
  persistent PI2 = 2 * pi;
  persistent f = @(p, t) p(2) * cos(PI2 * p(1) * t + p(3)) + p(5) * cos(PI2 * p(4) * t + p(6));
  % partial derivatives
  persistent fDfdp = @(p, t) [- PI2 * p(2) * t .* sin(PI2 * p(1) * t + p(3)) , cos(PI2 * p(1) * t + p(3)),  - p(2) * sin(PI2 * p(1) * t + p(3)),...
            -PI2 * p(5) * t .* sin(PI2 * p(4) * t + p(6)),  cos(PI2 * p(4) * t + p(6)), -p(5) * sin(PI2 * p(4) * t + p(6))];
  persistent settings = optimset ('dfdp', fDfdp);

  measFreq1 = measuredPeaksCh(1, 1);
  measAmpl1 = measuredPeaksCh(1, 2);
  measPhase1 = measuredPeaksCh(1, 3);

  measFreq2 = measuredPeaksCh(2, 1);
  measAmpl2 = measuredPeaksCh(2, 2);
  measPhase2 = measuredPeaksCh(2, 3);

  periods = 50;
  t = transpose(0 : 1/fs : periods * 1/min(measFreq1, measFreq2));  

  init = [measFreq1; measAmpl1; measPhase1; measFreq2; measAmpl2; measPhase2];

  samplesY = analysisBufferCh(1:length(t));

  [p, model_values, cvg, outp] = nonlin_curvefit(f, init, t, samplesY, settings);
  if p(1) ~= measFreq1 || p(4) ~= measFreq2
    % non-integer fundamental freq found
    % first fundamental
    [ampl, phaseShift] = fixMeasuredAmplPhase(p(2), p(3));
    measuredPeaksCh = [p(1), ampl, phaseShift];
    % second fundamental
    [ampl, phaseShift] = fixMeasuredAmplPhase(p(5), p(6));
    measuredPeaksCh = [measuredPeaksCh; p(4), ampl, phaseShift];
  end
end


function [fundLevelsCh, distortPeaksCh, calFile] = genCompensationPeaks(measuredPeaksCh, fs, compRequest, channelID, chMode, channelCnt, reloadCalFiles);
  
  persistent distortFreqs = cell(channelCnt, 1);
  persistent complAllPeaks = cell(channelCnt, 1);
  persistent calFiles = cell(channelCnt, 1);
  
  persistent prevPeaks = cell(channelCnt, 1);
  persistent sameFreqsCounter = zeros(channelCnt, 1);
  % how many cycles freqs must be same until declared stable - avoid artefacts caused by freqs change within the cycle
  persistent SAME_FREQS_ROUNDS = 2;
    
  % default values
  fundLevelsCh = [];
  distortPeaksCh = [];
  calFile = '';

  % check if new and stable
  areSame = areSameFreqs(measuredPeaksCh, prevPeaks{channelID});
  % remember for next round
  prevPeaks{channelID} = measuredPeaksCh;
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
        [distortFreqsCh, complAllPeaksCh, calFile] = loadPeaks(getFreqs(measuredPeaksCh), fs, channelID, chMode, compRequest);
        % beware - interpl used for interpolation does not work with NA values. We have to interpolate/fill the missing values here
        if find(isna(complAllPeaksCh))
          complAllPeaksCh = fillMissingCalPeaks(complAllPeaksCh);
        end
        % storing to persistent vars
        distortFreqs{channelID} = distortFreqsCh;
        complAllPeaks{channelID} = complAllPeaksCh;
        calFiles{channelID} = calFile;
      end
    
      % interpolating
      if ~isempty(complAllPeaks{channelID})
        % interpolate to current measured level
        complAllPeaksCh = complAllPeaks{channelID};
        % if JOINT compensation on playback side - peaks must be scaled to playAmpl levels
        global COMP_TYPE_JOINT;
        global DIR_PLAY;
        global direction;
        if compRequest.compType == COMP_TYPE_JOINT && direction == DIR_PLAY
          complAllPeaksCh = scalePeaksToPlayAmpls(complAllPeaksCh);
        end
        [fundLevelsCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs{channelID}, complAllPeaksCh);
        calFile = calFiles{channelID};
      end
    end
  end
end

% distortion peaks in complAllPeaksCh are scaled at ratio playAmpl/fundAmpl
function complAllPeaksCh = scalePeaksToPlayAmpls(complAllPeaksCh)
  global AMPL_IDX;  % = index of fundAmpl1
  global PLAY_AMPL_IDX;
  global PEAKS_START_IDX; 
  
  % TODO - scaling only by first fundamentals for now!
  playAmpls = complAllPeaksCh(:, PLAY_AMPL_IDX);
  knownPlayRowIDs = find(~isna(playAmpls));
  % not scaling first row - all fundAmpls are zero
  % removing first index
  knownPlayRowIDs(knownPlayRowIDs == 1) = [];
  % each row can have different scale
  scales = complAllPeaksCh(knownPlayRowIDs, PLAY_AMPL_IDX) ./ complAllPeaksCh(knownPlayRowIDs, AMPL_IDX);
  complAllPeaksCh(knownPlayRowIDs, AMPL_IDX:end) = complAllPeaksCh(knownPlayRowIDs, AMPL_IDX:end) .* scales;
  % must be sorted by AMPL_IDX for interpolation - order can have changed after scaling
  complAllPeaksCh = sortrows(complAllPeaksCh, AMPL_IDX);
end

function [distortFreqsCh, calPeaksCh, calFile] = loadPeaks(freqs, fs, channelID, chMode, compRequest)
  % values for no signal/no calfile
  distortFreqsCh = [];
  calPeaksCh = [];
  
  % re-reading cal file with one channel calib data
  calFile = genCalFilename(freqs, fs, compRequest.compType, compRequest.playChannelID, channelID,
    compRequest.playCalDevName, compRequest.recCalDevName, chMode, compRequest.extraCircuit);
  if exist(calFile, 'file')
    % loading calRec, initialising persistent vars
    load(calFile);

    calPeaksCh = calRec.peaks;
    % removing outdated rows
    calPeaksCh = removeOutdatedCalPeaks(calPeaksCh, time());

    if isempty(calPeaksCh)
      writeLog('WARN', 'Calib file %s has only outdated cal peaks, channel ID %d PASSING', calFile, channelID);
      calFile = '';
      return;
    end

    % adding edge rows for interpolation (not stored in the calfile)
    calPeaksCh = addEdgeCalPeaks(calRec.peaks);

    % distortFreqs are calculated for calRec.fundFreqs. However, in nonInteger mode the current fundFreqs can slightly differ.
    % Experiments show the harmonics levels and phases do not change much when fund freq changes a bit (tens of Hz).
    % Therefore the distortFreqs can be scaled safely to correspond to measured fund freqs
    % scaling by first fundFreq
    freqScale = freqs(1) / calRec.fundFreqs(1);
    distortFreqsCh = calRec.distortFreqs * freqScale;
    writeLog('INFO', 'Distortion peaks for channel ID %d read from calibration file %s', channelID, calFile);
  else
    writeLog('WARN', 'Did not find calib file %s, channel ID %d PASSING', calFile, channelID);
    calFile = '';
  end
end


function [fundLevelsCh, distortPeaksCh] = interpolatePeaks(measuredPeaksCh, channelID, distortFreqs, complAllPeaksCh)
  % calPeaks: time, fundPhaseDiff1, fundPhaseDiff2, playFundAmpl1, playFundAmpl2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  % WARN: ALL peaks must be known (no NA values!)
  global AMPL_IDX;  % = index of fundAmpl1
  global PEAKS_START_IDX; 
  distortPeaksCh = [];
  
  allDPeaksC = complAllPeaksCh(:, PEAKS_START_IDX:end);
  if ~isempty(allDPeaksC) 
    % the actual interpolation
    
    % levels = AMPL_IDX column
    levels = complAllPeaksCh(:, AMPL_IDX);
    
    % amplitude of first fundamental
    currentLevel = measuredPeaksCh(1, 2);  
    % interpolate, non-complex output!!!
    

    % interp1 is slow (10ms in internal ppval()), run only once for all freqs
    peaksAtLevel = interp1(levels, allDPeaksC , currentLevel, 'linear', 'extrap');
    peaksAtLevel = transpose(peaksAtLevel);
    distortPeaksCh = [transpose(distortFreqs), abs(peaksAtLevel), angle(peaksAtLevel)];
  end
  % since currentPeaksCh are already interpolated to current level, fundLevels = measuredPeaksCh (without phase info)
  fundLevelsCh = measuredPeaksCh(:, 1:2);
end