% calRequest.calFreqs - optional 1/2 values. If not empty, wait for these freqs to come (in both channels), with timeout
function [result, runID, correctRunsCounter, msg] = calibrate(calBuffer, prevFundPeaks, fs, calRequest, restart)
  persistent channelCnt = columns(calBuffer);
  % consts
  % max number of calibration runs. When reached, calibration quits with FAILED_RESULT
  persistent MAX_RUNS = 50;
  
  % maximum fund ampl. difference between subsequent runs to consider stable fundPeaks
  persistent MAX_AMPL_DIFF = db2mag(-80);
  
  % memory of previous peaks, subjected to averaging  
  persistent allFundPeaks = cell(channelCnt, MAX_RUNS);
  persistent allDistortPeaks = cell(channelCnt, MAX_RUNS);
  
  persistent runID = 0;
  global NOT_FINISHED_RESULT;
  global FAILING_RESULT;
  global RUNNING_OK_RESULT;

  persistent correctRunsCounter = zeros(channelCnt, 1);
  
  msg = '';
  
  calFreqReq = calRequest.calFreqReq;

  if (restart)
    % resetting all relevant persistent vars
    runID = 0;
    correctRunsCounter = zeros(channelCnt, 1);
    allFundPeaks = cell(channelCnt, MAX_RUNS);
    allDistortPeaks = cell(channelCnt, MAX_RUNS);    
  endif

  runID += 1;
  writeLog('DEBUG', 'Measuring calibration peaks for run ID %d', runID);    

  % calculate FFT peaks
  [fundPeaks, distortPeaks] = getHarmonics(calBuffer, fs);
  for channelID = 1:channelCnt
    % shift distortPeaks to zero time of fundPeaks and store to runPeaks
    fundPeaksCh = fundPeaks{channelID};
    distortPeaksCh = distortPeaks{channelID};
    prevFundPeaksCh = prevFundPeaks{channelID};
    % check if exist, stable, resp. fitting the calFreqs specs
    if ~isempty(calFreqReq)      
      calFreqReqCh = calFreqReq{channelID};
    else
      calFreqReqCh = [];
    end
    checksOK = false;
    % same freqs check
    if areSameFreqs(fundPeaksCh, prevFundPeaksCh)
      % same levels check
      if areSameLevels(fundPeaksCh, prevFundPeaksCh, MAX_AMPL_DIFF)
        % req. freqs check
        if isempty(calFreqReqCh) || isequal(getFreqs(calFreqReqCh), getFreqs(fundPeaksCh))
          % req. levels check 
          if isempty(calFreqReqCh) || checkCorrectLevels(calFreqReqCh, fundPeaksCh)
            % all checks OK, this run is OK
            checksOK = true;
          else
            writeLog('WARN', 'Measured levels different from requested, resetting counter');
            msg = 'Levels outside of the requested range';
          endif          
        else
          writeLog('WARN', 'Different fund freqs from requested, resetting counter');
          msg = 'Freqs different from requested';
        endif        
      else
        writeLog('WARN', 'Different levels in run %d from previous run, resetting counter', runID);
        msg = 'Unstable levels';
      endif
    else
      writeLog('WARN', 'Different/zero fund freqs in run %d from previous run, resetting counter', runID);
      msg = 'Unstable freqs';
    endif
            
    if ~checksOK
      % reset the counter
      correctRunsCounter(channelID) = 0;
      % reset saved peaks from previous runs
      allFundPeaks = cell(channelCnt, MAX_RUNS);
      allDistortPeaks = cell(channelCnt, MAX_RUNS);

      % DEBUG printing values
      writeLog('DEBUG', 'This round fundPeaksCh: %s', disp(fundPeaksCh));
      writeLog('DEBUG', 'Prev. round fundPeaksCh: %s', disp(prevFundPeaksCh));
      result = FAILING_RESULT;
      % go to next channel
      break;
    else
      writeLog('DEBUG', 'Same fund peaks as in previous run + correct freqs and levels in in run %d, using for averaging', runID);
      % same non-empty freqs from previous run, can continue
      correctRunsCounter(channelID) += 1;
      % save peaks for averaging
      if hasAnyPeak(distortPeaksCh)
        % time shift distortPeaks to zero phase of fundPeaks        
        distortPeaksCh = phasesAtZeroTimeCh(fundPeaksCh, distortPeaksCh);
        % now distortPeaksCh are zero-time based.
      endif
      % store peaks of this run to persistent variable
      % some allXXXPeaks lines will stay empty, but calculateAvgPeaks() ignores them
      allFundPeaks{channelID, runID} = fundPeaksCh;
      allDistortPeaks{channelID, runID} = distortPeaksCh;
      result = RUNNING_OK_RESULT;
    endif
  endfor
  
  % runPeaks are updated, now checking RUN conditions
  if any(correctRunsCounter < calRequest.calRuns) && runID < MAX_RUNS
    % some of the channels have not reached cal runs of same freqs
    % and still can run next time
    % result is already set
    return;
  end
      
  if all(correctRunsCounter >= calRequest.calRuns)
    % enough stable runs, storing the average
    writeLog('INFO', 'Enough runs %d, calibrating with measured peaks', runID); 
    timestamp = time();

    % storing joint directions cal file
    % each channel stored separately
    calFileStructs = cell(channelCnt, 1);
    for channelID = 1:channelCnt
      % determine peaks from runs
      writeLog('DEBUG', 'Determining avg peaks for channelID %d', channelID);
      [fundPeaksCh, distortPeaksCh] = detAveragePeaks(allFundPeaks(channelID, :), allDistortPeaks(channelID, :))
      if hasAnyPeak(fundPeaksCh)
        % storing to calFile
        calFile = genCalFilename(getFreqs(fundPeaksCh), fs, calRequest.compType, calRequest.playChannelID, channelID, calRequest.chMode, calRequest.extraCircuit);
        % param doSave = false - not storing yet
        [calFileStructs(channelID)] = saveCalFile(fundPeaksCh, distortPeaksCh, fs, calFile, timestamp, false);
      else
        writeLog('WARN', 'No fundaments found for channel ID %d, not storing its calibration file', channelID);
      endif
    endfor
    
    if channelCnt >= 2
      % at least two channels, we can measure/store avg. fund phase chan2 vs. chan1
      avgPhaseDiffs = detAveragePhaseDiffs(allFundPeaks, MAX_RUNS);
    else
      avgPhaseDiffs = NA;
    endif
    
    % store calfile, update avgPhaseDiffs if required
    for channelID = 1:channelCnt
        calFileStruct = calFileStructs{channelID};
        calRec = calFileStruct.calRec;
        calFile = calFileStruct.fileName;
        if ~isna(avgPhaseDiffs)
          writeLog('DEBUG', 'Updating the newly-added rows to be stored to %s with non-zero avg phase difference of %s', calFile, disp(avgPhaseDiffs));
          calRec.peaks = updatePhaseDiffsInPeaks(calRec.peaks, avgPhaseDiffs, calFileStruct.addedRowIDs);
        endif
        writeLog('INFO', 'Storing avg phase difference to newly-added rows in calfiles');
        save(calFile, 'calRec');
    endfor

    global FINISHED_RESULT;
    result = FINISHED_RESULT;
    
  else
    writeLog('WARN', "Reached %d max runs yet did not have at least %d same fund peaks runs in all channels, failing the calibration", MAX_RUNS, calRequest.calRuns);
    msg = 'Timed out without freqs';
    global FAILED_RESULT;
    result = FAILED_RESULT;
  endif
  
  % reset values for next calibration
  runID = 0;
  correctRunsCounter = zeros(channelCnt, 1);
  allFundPeaks = cell(channelCnt, MAX_RUNS);
  allDistortPeaks = cell(channelCnt, MAX_RUNS);
endfunction

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
        endif
      endif
    endif
  endfor
  % found no problem, check OK
  result = true;
endfunction

% determines average phase diffs between second and first channels.
% avgPhaseDiffs = row vector, diff for each fundament
function avgPhaseDiffs = detAveragePhaseDiffs(allFundPeaks, MAX_RUNS)
  writeLog('DEBUG', 'Determining avg fund phase diff between channel 2 and 1');
  phaseDiffsC = cell();
  for id = 1:MAX_RUNS
    fundPeaksCh1 = allFundPeaks{1, id};
    fundPeaksCh2 = allFundPeaks{2, id};
    if hasAnyPeak(fundPeaksCh1) && isequal(fundPeaksCh1(:, 1), fundPeaksCh2(:, 1))
      % both have a peak, both same freqs, store the phase diff
      % NOTE - phases are not generally in <-pi, +pi> range which will produce nonsense when averaging. Averaging complex numbers instead      
      phaseDiffsC{end + 1} = exp(i * fundPeaksCh2(:, 3)) ./ exp(i * fundPeaksCh1(:, 3));
    endif
  endfor
  % remove first row to avoid transitions - same as for averaging peaks
  if length(phaseDiffsC) > 1
    phaseDiffsC(1) = [];
  endif
  
  % cell array cannot be averaged -> converting to properly oriented matrix
  phaseDiffsC = transpose(cell2mat(phaseDiffsC));
  % averaging, only angle is required
  avgPhaseDiffs = mean(angle(phaseDiffsC));
endfunction

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
  endif
  
  if hasAnyPeak(mergedDistortPeaksCh)
    avgDistortPeaksCh = calculateAvgPeaks(mergedDistortPeaksCh, runsCnt);
  else
    avgDistortPeaksCh = [];  
  endif
endfunction

% merging all rows of non-empty peaks matrices in allPeaksCh to single matrix. 
% First and last non-empty peaks matrices are skipped - could contain dirty transitional values
% allPeaksCh - cell array(1, MAX_RUNS) of peaks matrices
% mergedPeaksCh - regular peaks matrix(N, 3)
function [mergedPeaksCh, runsCnt] = mergePeaks(allPeaksCh)
  mergedPeaksCh = [];
  emptyIDs = find(cellfun('isempty', allPeaksCh));
  % remove empty cells
  allPeaksCh(:, emptyIDs) = [];
  % remove first item - may contain transitional non-stable data
  if size(allPeaksCh, 2) > 1
    allPeaksCh(:, 1) = [];
  endif
  
  runsCnt = size(allPeaksCh, 2);
  for runID = 1 : runsCnt
    runPeaksCh = allPeaksCh{runID};
    if ~isempty(runPeaksCh)
      mergedPeaksCh = [mergedPeaksCh; runPeaksCh];
    endif
  endfor
endfunction


% return average peaks for each frequency found in mergedPeaksCh
% runsCnt - number of runs within mergedPeaksCh. Is used for dropping frequencies with little count
% allPeaksCh can contain zero rows - ignored
function avgPeaksCh = calculateAvgPeaks(mergedPeaksCh, runsCnt);
  % const
  % minimum occurence of given frequency distortion in all runsCnt to be included in the averaged peaks
  % 30%
  persistent MIN_OCCURENCE_LIMIT = 0.3;
  avgPeaksCh = [];
  
  uniqFreqs = unique(mergedPeaksCh(:, 1));
  uniqFreqs = sort(uniqFreqs);
  
  % include only frequencies which occur minRequiredCnt out of runsCnt
  % less frequent frequencies must be ignored because their interpolation during compensation creates false compensation signals
  minRequiredCnt = runsCnt * MIN_OCCURENCE_LIMIT;
  % average for each freq
  for freq = transpose(uniqFreqs)
    % only for nonzero freqs
    if (freq > 0)
      freqIDs = find(mergedPeaksCh(:, 1) == freq);
      % averaging requires complex values    
      valuesOfFreq = mergedPeaksCh(freqIDs, 2:3);
      valuesCnt = rows(valuesOfFreq);
      if valuesCnt >= minRequiredCnt
        % only frequencies measured in almost every run can be considered for compensation
        cValues = valuesOfFreq(:, 1) .* exp(i * valuesOfFreq(:, 2));
        avgCValue = mean(cValues);
        avgPeak = [freq, abs(avgCValue), angle(avgCValue)];
        avgPeaksCh = [avgPeaksCh; avgPeak];
      else
        writeLog('WARN', 'Distort freq %d occured only %d out of %d runs, below the required min count %d, not being included in avgPeaksCh', freq, valuesCnt, minRequiredCnt, runsCnt);
      endif
    endif
  endfor
endfunction