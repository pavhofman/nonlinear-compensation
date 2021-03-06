% calRequest.calFreqs - optional 1/2 values. If not empty, wait for these freqs to come (in both channels), with timeout
function [result, lastRunID, lastCorrectRunsCounter, msg] = calibrate(calBuffer, measuredPeaks, fs, calRequest, chMode, restart, nonInteger)
  persistent channelCnt = columns(calBuffer);
  persistent prevFundPeaks = cell(channelCnt, 1);

  % consts
  % max number of calibration runs. When reached, calibration quits with FAILED_RESULT
  persistent MAX_RUNS = 100;
  
  % maximum fund ampl. difference between subsequent runs to consider stable fundPeaks
  global maxAmplDiff;
  
  % memory of previous peaks, subjected to averaging  
  persistent allFundPeaks = cell(channelCnt, MAX_RUNS);
  persistent allDistortPeaks = cell(channelCnt, MAX_RUNS);
  
  persistent runID = 0;
  global NOT_FINISHED_RESULT;
  global FAILING_RESULT;
  global RUNNING_OK_RESULT;
  
  global INTEGER_FS_FFT_MULTIPLE;
  
  persistent correctRunsCounter = zeros(channelCnt, 1);
  
  msg = '';
  
  calFreqReq = calRequest.calFreqReq;

  if (restart)
    % resetting all relevant persistent vars
    runID = 0;
    correctRunsCounter = zeros(channelCnt, 1);
    allFundPeaks = cell(channelCnt, MAX_RUNS);
    allDistortPeaks = cell(channelCnt, MAX_RUNS);
    prevFundPeaks = cell(channelCnt, 1);
  end

  runID += 1;
  writeLog('DEBUG', 'Measuring calibration peaks for run ID %d', runID);

  activeChannelIDs = getActiveChannelIDs(chMode, channelCnt);
  % calculate FFT peaks
  if ~nonInteger
    % integer freq mode
    % all channels at once with FFT, with length = INTEGER_FS_FFT_MULTIPLE * fs
    fftLength = INTEGER_FS_FFT_MULTIPLE * fs;
    [fundPeaks, distortPeaks] = getHarmonics(fftLength, calBuffer(rows(calBuffer) - fftLength + 1:end, :), fs, 'rect');
  else
    % empty, will calculate for each channel in loop
    fundPeaks = cell(channelCnt, 1);
    distortPeaks = cell(channelCnt, 1);
  end


  for channelID = activeChannelIDs
    prevFundPeaksCh = prevFundPeaks{channelID};
    measuredPeaksCh = measuredPeaks{channelID};
    % check if exist, stable, resp. fitting the calFreqs specs
    if ~isempty(calFreqReq)      
      calFreqReqCh = calFreqReq{channelID};
    else
      calFreqReqCh = [];
    end

    if nonInteger
      % each channel has FFT length
      newLength = getFFTLength(fs, measuredPeaksCh, floor(rows(calBuffer)/2));
      [fundPeaksChCell, distortPeaksChCell] = getHarmonics(newLength, calBuffer(rows(calBuffer) - newLength + 1:end, channelID), fs, true, 'hanning');
      fundPeaksCh = fundPeaksChCell{1};
      distortPeaksCh = distortPeaksChCell{1};
    else
      % already calculated before the loop by all-channels FFT
      fundPeaksCh = fundPeaks{channelID};
      distortPeaksCh = distortPeaks{channelID};
    end


    % default value
    checksOK = false;
    % same freqs check
    if ~areSameFreqs(fundPeaksCh, prevFundPeaksCh)
      writeLog('WARN', 'Different/zero fund freqs in run %d from previous run, resetting counter', runID);
      msg = 'Unstable freqs';
    % stable levels check
    elseif ~areSameLevels(fundPeaksCh, prevFundPeaksCh, maxAmplDiff)
      writeLog('WARN', 'Different levels in run %d from previous run, resetting counter', runID);
      msg = 'Unstable levels';
    % req freqs check
    elseif ~isempty(calFreqReqCh) && ~areSameFreqs(calFreqReqCh, fundPeaksCh)
      writeLog('WARN', 'Different fund freqs from requested, resetting counter');
      msg = 'Freqs different from requested';
    %req levels check
    elseif ~isempty(calFreqReqCh) && ~checkCorrectLevels(calFreqReqCh, fundPeaksCh)
      writeLog('WARN', 'Measured levels different from requested, resetting counter');
      msg = 'Levels outside of the requested range';
    else
      % all checks OK, this run is OK
      checksOK = true;
    end

    % remember for next round - using peaks calculated by analysis which uses the same procedure
    prevFundPeaks{channelID} = fundPeaksCh;

    if checksOK
      % OK, doing the actual calibration
      writeLog('DEBUG', 'Same fund peaks as in previous run + correct freqs and levels in in run %d, using for averaging', runID);

      % same non-empty freqs from previous run, can continue
      correctRunsCounter(channelID) += 1;
      % save peaks for averaging
      if hasAnyPeak(distortPeaksCh)
        % time shift distortPeaks to zero phase of fundPeaks
        distortPeaksCh = phasesAtZeroTimeCh(fundPeaksCh, distortPeaksCh);
        % now distortPeaksCh are zero-time based.
      end
      % store peaks of this run to persistent variable
      % some allXXXPeaks lines will stay empty, but calculateAvgPeaks() ignores them
      allFundPeaks{channelID, runID} = fundPeaksCh;
      allDistortPeaks{channelID, runID} = distortPeaksCh;
      result = RUNNING_OK_RESULT;
    else
      % reset the counter
      correctRunsCounter(channelID) = 0;
      % reset saved peaks from previous runs
      allFundPeaks = cell(channelCnt, MAX_RUNS);
      allDistortPeaks = cell(channelCnt, MAX_RUNS);

      % DEBUG printing values
      writeLog('DEBUG', 'Checks failed: This round fundPeaksCh: %s', disp(fundPeaksCh));
      writeLog('DEBUG', 'Checks failed: Prev. round prevFundPeaksCh: %s', disp(prevFundPeaksCh));
      result = FAILING_RESULT;
    end
  end
  
  % runPeaks are updated, now checking RUN conditions
  if any(correctRunsCounter(activeChannelIDs) < calRequest.calRuns) && runID < MAX_RUNS
    % some of the channels have not reached cal runs of same freqs
    % and still can run next time
    % result is already set
    lastRunID = runID;
    lastCorrectRunsCounter = correctRunsCounter;
    return;
  end
      
  if all(correctRunsCounter(activeChannelIDs) >= calRequest.calRuns)
    % enough stable runs, storing the average
    writeLog('INFO', 'Enough runs %d, calibrating with measured peaks', runID); 
    timestamp = time();

    % storing joint directions cal file
    % each channel stored separately
    calFileStructs = cell(channelCnt, 1);
    for channelID = activeChannelIDs
      % determine peaks from runs
      writeLog('DEBUG', 'Determining avg peaks for channelID %d', channelID);
      [fundPeaksCh, distortPeaksCh] = detAveragePeaks(allFundPeaks(channelID, :), allDistortPeaks(channelID, :))
      if hasAnyPeak(fundPeaksCh)
        % storing to calFile - under current chMode
        calFile = genCalFilename(getFreqs(fundPeaksCh), fs, calRequest.compType, calRequest.playChannelID, channelID,
          calRequest.playCalDevName, calRequest.recCalDevName, chMode, calRequest.extraCircuit);
        playAmplsCh = calRequest.playAmpls{calRequest.playChannelID};
        % param doSave = false - not storing yet        
        [calFileStructs(channelID)] = saveCalFile(fundPeaksCh, distortPeaksCh, fs, calFile, playAmplsCh, timestamp, false);
      else
        writeLog('WARN', 'No fundaments found for channel ID %d, not storing its calibration file', channelID);
      end
    end
    
    if channelCnt >= 2
      % at least two channels, we can measure/store avg. fund phase theOtherChID vs. ANALYSED_CH_ID
      avgPhaseDiffs = detAveragePhaseDiffs(allFundPeaks);
    else
      avgPhaseDiffs = NA;
    end
    
    % store calfile, update avgPhaseDiffs if required
    for channelID = activeChannelIDs
        calFileStruct = calFileStructs{channelID};
        calRec = calFileStruct.calRec;
        calFile = calFileStruct.fileName;
        if ~isna(avgPhaseDiffs)
          writeLog('DEBUG', 'Updating the newly-added rows to be stored to %s with non-zero avg phase difference of %s', calFile, disp(avgPhaseDiffs));
          calRec.peaks = updatePhaseDiffsInPeaks(calRec.peaks, avgPhaseDiffs, calFileStruct.addedRowIDs);
        end
        writeLog('INFO', 'Storing avg phase difference to newly-added rows in calfiles');
        save(calFile, 'calRec');
    end

    global FINISHED_RESULT;
    result = FINISHED_RESULT;
    
  else
    writeLog('WARN', "Reached %d max runs yet did not have at least %d same fund peaks runs in all channels, failing the calibration", MAX_RUNS, calRequest.calRuns);
    msg = 'Timed out without freqs';
    global FAILED_RESULT;
    result = FAILED_RESULT;
  end
  
  % reset values for next calibration
  runID = 0;
  correctRunsCounter = zeros(channelCnt, 1);
  allFundPeaks = cell(channelCnt, MAX_RUNS);
  allDistortPeaks = cell(channelCnt, MAX_RUNS);
  lastRunID = runID;
  lastCorrectRunsCounter = correctRunsCounter;  
end

% have fundPeaksCh levels within range of calFreqsCh?
% calFreqsCh, fundPeaksCh - never empty, always same freqs, sorted by freqs!
function result = checkCorrectLevels(calFreqReqCh, fundPeaksCh)
  % calFreqReqCh format: [F1,minAmpl,maxAmpl;F2,minAmpl,maxAmpl] OR [F1,NA,NA; F2,NA,NA]
  for rowID = 1:rows(fundPeaksCh)
    calFreqReqRow = calFreqReqCh(rowID, :);
    minAmpl = calFreqReqRow(2);
    if isna(minAmpl)
      % minAmpl NA, no check
      continue;
    else
      fundAmpl = fundPeaksCh(rowID, 2);
      if fundAmpl < minAmpl
        % too small
        result = false;
        return;
      else
        maxAmpl = calFreqReqRow(3);
        if ~isna(maxAmpl) && fundAmpl> maxAmpl
          % too large
          result = false;
          return;
        end
      end
    end
  end
  % found no problem, check OK
  result = true;
end

% determines average phase diffs between analysed and the other channels.
% avgPhaseDiffs = row vector, diff for each fundament
function avgPhaseDiffs = detAveragePhaseDiffs(allFundPeaks)
  global ANALYSED_CH_ID;
  persistent otherChannelID = getTheOtherChannelID(ANALYSED_CH_ID);

  writeLog('DEBUG', 'Determining avg fund phase diff between channel %d and %d', ANALYSED_CH_ID, otherChannelID);
  phaseDiffsC = cell();
  for id = 1:columns(allFundPeaks)
    fundPeaksChOther = allFundPeaks{otherChannelID, id};
    fundPeaksChAn = allFundPeaks{ANALYSED_CH_ID, id};
    if hasAnyPeak(fundPeaksChOther)  && hasAnyPeak(fundPeaksChAn) && isequal(fundPeaksChOther(:, 1), fundPeaksChAn(:, 1))
      % both have a peak, both same freqs, store the phase diff
      % NOTE - phases are not generally in <-pi, +pi> range which will produce nonsense when averaging. Averaging complex numbers instead      
      phaseDiffsC{end + 1} = exp(i * fundPeaksChAn(:, 3)) ./ exp(i * fundPeaksChOther(:, 3));
    end
  end
  % remove first row to avoid transitions - same as for averaging peaks
  if length(phaseDiffsC) > 1
    phaseDiffsC(1) = [];
  end
  
  % cell array cannot be averaged -> converting to properly oriented matrix
  phaseDiffsC = transpose(cell2mat(phaseDiffsC));
  if ~isempty(phaseDiffsC)
    % averaging, only angle is required
    avgPhaseDiffs = mean(angle(phaseDiffsC));
  else
    avgPhaseDiffs = [0, 0];
  end
end

% averaging fundPeaks amplitude, distortPeaks all for each frequency
% allXXXPeaksCh - cell array(1, MAX_RUNS) of peaks matrices
function [avgFundPeaksCh, avgDistortPeaksCh] = detAveragePeaks(allFundPeaksCh, allDistortPeaksCh)
  mergedFundPeaksCh = mergePeaks(allFundPeaksCh);
  % allDistortPeaks are already 0-time based which means all fundamentals at phase 0
  % zeroing mergedFundPeaksCh phases first
  mergedFundPeaksCh(:, 3) = 0;
  
  [mergedDistortPeaksCh, runsCnt] = mergePeaks(allDistortPeaksCh);
  
  % calculate only if some fund and distort peaks are found
  if hasAnyPeak(mergedFundPeaksCh)
    avgFundPeaksCh = calculateAvgPeaks(mergedFundPeaksCh, runsCnt);
  else
    avgFundPeaksCh = [];  
  end
  
  if hasAnyPeak(mergedDistortPeaksCh)
    avgDistortPeaksCh = calculateAvgPeaks(mergedDistortPeaksCh, runsCnt);
  else
    avgDistortPeaksCh = [];  
  end
end

% merging all rows of non-empty peaks matrices in allPeaksCh to single matrix. 
% first DROP_CAL_RUNS non-empty peaks matrices are skipped - could contain dirty transitional values
% allPeaksCh - cell array(1, MAX_RUNS) of peaks matrices
% mergedPeaksCh - regular peaks matrix(N, 3)
function [mergedPeaksCh, runsCnt] = mergePeaks(allPeaksCh)
  global DROP_CAL_RUNS;
  mergedPeaksCh = [];
  emptyIDs = find(cellfun('isempty', allPeaksCh));
  % remove empty cells
  allPeaksCh(:, emptyIDs) = [];
  % remove first DROP_CAL_RUNS items - may contain transitional non-stable data
  if size(allPeaksCh, 2) > DROP_CAL_RUNS
    allPeaksCh(:, 1:DROP_CAL_RUNS) = [];
  end
  
  runsCnt = size(allPeaksCh, 2);
  for runID = 1 : runsCnt
    runPeaksCh = allPeaksCh{runID};
    if ~isempty(runPeaksCh)
      mergedPeaksCh = [mergedPeaksCh; runPeaksCh];
    end
  end
end


% return average peaks for each frequency found in mergedPeaksCh
% runsCnt - number of runs within mergedPeaksCh. Is used for dropping frequencies with little count
% allPeaksCh can contain zero rows - ignored
function avgPeaksCh = calculateAvgPeaks(mergedPeaksCh, runsCnt);
  % const
  % minimum occurence of given frequency distortion in all runsCnt to be included in the averaged peaks
  % 30%
  persistent MIN_OCCURENCE_LIMIT = 0.3;
  % tolerance for grouping in unique (in Hz)
  persistent UNIQUE_FREQ_TOLERANCE = 0.1;
  avgPeaksCh = [];
  
  [uniqFreqs, ~, sameRowIDs] = uniqueWithTol(mergedPeaksCh(:, 1), UNIQUE_FREQ_TOLERANCE);
  % include only frequencies which occur minRequiredCnt out of runsCnt
  % less frequent frequencies must be ignored because their interpolation during compensation creates false compensation signals
  minRequiredCnt = runsCnt * MIN_OCCURENCE_LIMIT;
  % average for each freq

  for freqID = 1:length(uniqFreqs)
    freq = uniqFreqs(freqID);
    % only for nonzero freqs
    if (freq > 0)
      thisFreqPeaksIDs = find(sameRowIDs == freqID);
      % averaging requires complex values    
      valuesOfFreq = mergedPeaksCh(thisFreqPeaksIDs, 2:3);
      valuesCnt = rows(valuesOfFreq);
      if valuesCnt >= minRequiredCnt
        % only frequencies measured in almost every run can be considered for compensation
        cValues = valuesOfFreq(:, 1) .* exp(i * valuesOfFreq(:, 2));
        avgCValue = mean(cValues);
        avgPeak = [freq, abs(avgCValue), angle(avgCValue)];
        avgPeaksCh = [avgPeaksCh; avgPeak];
      else
        writeLog('WARN', 'Distort freq %d occured only %d out of %d runs, below the required min count %d, not being included in avgPeaksCh', freq, valuesCnt, minRequiredCnt, runsCnt);
      end
    end
  end
  % sorting by freq ASC
  avgPeaksCh = sortrows(avgPeaksCh, 1);
end