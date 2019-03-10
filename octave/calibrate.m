% calFreqs - optional 1/2 values. If not empty, wait for these freqs to come (in both channels), with timeout
function [result, runID, sameFreqsCounter, msg] = calibrate(calBuffer, prevFundPeaks, fs, calFreqs, deviceName, extraCircuit, restart)
  persistent channelCnt = columns(calBuffer);
  % consts
  % number of consequent calibration runs which contribute to final averaged value
  persistent CAL_RUNS = 10;
  % max number of calibration runs. When reached, calibration quits with FAILED_RESULT
  persistent MAX_RUNS = 50;
  
  % maximum fund ampl. difference between runs to consider stable fundPeaks
  persistent MAX_AMPL_DIFF = db2mag(-40);
  
  % memory of previous peaks, subjected to averaging  
  persistent allFundPeaks = cell(channelCnt, MAX_RUNS);
  persistent allDistortPeaks = cell(channelCnt, MAX_RUNS);
  
  persistent runID = 0;
  global NOT_FINISHED_RESULT;
  global FAILING_RESULT;
  global RUNNING_OK_RESULT;

  persistent sameFreqsCounter = zeros(channelCnt, 1);
  
  msg = '';

  if (restart)
    % resetting all relevant persistent vars
    runID = 0;
    sameFreqsCounter = zeros(channelCnt, 1);
    allFundPeaks = cell(channelCnt, MAX_RUNS);
    allDistortPeaks = cell(channelCnt, MAX_RUNS);    
  endif

  runID += 1;
  printf('Measuring calibration peaks for run ID %d\n', runID);    

  % calculate FFT peaks
  [fundPeaks, distortPeaks] = getHarmonics(calBuffer, fs);
  for channelID = 1:channelCnt
    % shift distortPeaks to zero time of fundPeaks and store to runPeaks
    fundPeaksCh = fundPeaks{channelID};
    distortPeaksCh = distortPeaks{channelID};    
    prevFundPeaksCh = prevFundPeaks{channelID}
    % check if exist, stable, resp. equal to calFreqs (calfreqs are already a sorted column - see run_process_cmd.m)
    areSame = areSameExistingPeaks(fundPeaksCh, prevFundPeaksCh, MAX_AMPL_DIFF);
    areCorrect = isempty(calFreqs) || isequal(calFreqs, getFreqs(fundPeaksCh));
    areSameAndCorrect = areSame && areCorrect;
    
    if ~areSameAndCorrect
      % are different or none
      % reset the counter
      sameFreqsCounter(channelID) = 0;
      % reset saved peaks from previous runs
      allFundPeaks = cell(channelCnt, MAX_RUNS);
      allDistortPeaks = cell(channelCnt, MAX_RUNS);

      % DEBUG printing values
      printf('This round fundPeaksCh:')
      disp(fundPeaksCh);
      printf('Prev. round fundPeaksCh:')
      disp(prevFundPeaksCh);
      printf('Different/zero fund freqs or different ampls in run %d from previous run, resetting counter\n', runID);
      msg = 'Unstable/different freqs';
      result = FAILING_RESULT;
      % go to next channel
      break;
    else
      printf('Same fund peaks as in previous run in in run %d, using for averaging\n', runID);
      % same non-empty freqs from previous run, can continue
      sameFreqsCounter(channelID) += 1;
      % save peaks for averaging
      if hasAnyPeak(distortPeaksCh)
        % time shift distortPeaks to zero phase of fundPeaks        
        distortPeaksCh = phasesAtZeroTimeCh(fundPeaksCh, distortPeaksCh);
        % now distortPeaksCh are zero-time based. Phases in fundPeaksCh must be kept for storing into calfile!
      endif
      % store peaks of this run to persistent variable
      % some allXXXPeaks lines will stay empty, but calculateAvgPeaks() ignores them
      allFundPeaks{channelID, runID} = fundPeaksCh;
      allDistortPeaks{channelID, runID} = distortPeaksCh;      
      result = RUNNING_OK_RESULT;
    endif
  endfor
  
  % runPeaks are updated, now checking RUN conditions
  if any(sameFreqsCounter < CAL_RUNS) && runID < MAX_RUNS
    % some of the channels have not reached cal runs of same freqs
    % and still can run next time
    % result is already set
    return;
  end
      
  if all(sameFreqsCounter >= CAL_RUNS)
    % enough stable runs, storing the average
    printf('Enough runs, calibrating with measured peaks\n'); 
    timestamp = time();

    % storing joint directions cal file
    % each channel stored separately      
    for channelID = 1:channelCnt
      % determine peaks from runs
      [fundPeaksCh, distortPeaksCh] = detAveragePeaks(allFundPeaks(channelID, :), allDistortPeaks(channelID, :))
      if hasAnyPeak(fundPeaksCh)
        saveCalFile(fundPeaksCh, distortPeaksCh, fs, channelID, timestamp, deviceName, extraCircuit);
      else
        printf('No fundaments found for channel ID %d, not storing its calibration file\n', channelID);
      endif
    endfor
    global FINISHED_RESULT;
    result = FINISHED_RESULT;
    
  else
    printf("Reached %d max runs yet did not have at least %d same fund peaks runs in all channels, failing the calibration\n", MAX_RUNS, CAL_RUNS);
    msg = 'Timed out without freqs';
    global FAILED_RESULT;
    result = FAILED_RESULT;
  endif
  
  % reset values for next calibration
  runID = 0;
  sameFreqsCounter = zeros(channelCnt, 1);
  allFundPeaks = cell(channelCnt, MAX_RUNS);
  allDistortPeaks = cell(channelCnt, MAX_RUNS);
endfunction
  

% averaging fundPeaks amplitude, distortPeaks all for each frequency
% allXXXPeaksCh - cell array(1, MAX_RUNS) of peaks matrices
function [avgFundPeaksCh, avgDistortPeaksCh] = detAveragePeaks(allFundPeaksCh, allDistortPeaksCh)
  mergedFundPeaksCh = mergePeaks(allFundPeaksCh);
  % allDistortPeaks are already 0-time based which means all fundamentals at phase 0
  % zeroing mergedFundPeaksCh phases first
  mergedFundPeaksCh(:, 3) = 0;
  
  mergedDistortPeaksCh = mergePeaks(allDistortPeaksCh);
  
  % calculate only if some fund and distort peaks are found
  if hasAnyPeak(mergedFundPeaksCh)
    avgFundPeaksCh = calculateAvgPeaks(mergedFundPeaksCh);
  else
    avgFundPeaksCh = [];  
  endif
  
  if hasAnyPeak(mergedDistortPeaksCh)
    avgDistortPeaksCh = calculateAvgPeaks(mergedDistortPeaksCh);  
  else
    avgDistortPeaksCh = [];  
  endif
endfunction

% merging all rows of non-empty peaks matrices in allPeaksCh to single matrix. 
% First and last non-empty peaks matrices are skipped - could contain dirty transitional values
% allPeaksCh - cell array(1, MAX_RUNS) of peaks matrices
% mergedPeaksCh - regular peaks matrix(N, 3)
function mergedPeaksCh = mergePeaks(allPeaksCh)
  mergedPeaksCh = [];
  emptyIDs = find(cellfun('isempty', allPeaksCh));
  % remove empty cells
  allPeaksCh(:, emptyIDs) = [];
  % remove first and last item - may contain transitional non-stable data
  if size(allPeaksCh, 2) > 2
    allPeaksCh(:, 1) = [];
    allPeaksCh(:, end) = [];
  endif
  
  for runID = 1 : size(allPeaksCh, 2)
    peaksCh = allPeaksCh{runID};
    if ~isempty(peaksCh)
      mergedPeaksCh = [mergedPeaksCh; peaksCh];
    endif
  endfor
endfunction


% return average peaks for each frequency found in mergedPeaksCh
% allPeaksCh can contain zero rows - ignored
function avgPeaksCh = calculateAvgPeaks(mergedPeaksCh);
  avgPeaksCh = [];
  
  uniqFreqs = unique(mergedPeaksCh(:, 1));
  uniqFreqs = sort(uniqFreqs);
  % average for each freq
  for freq = transpose(uniqFreqs)
    % only for nonzero freqs
    if (freq > 0)
      freqIDs = find(mergedPeaksCh(:, 1) == freq);
      % averaging requires complex values    
      values = mergedPeaksCh(freqIDs, 2:3);
      cValues = values(:, 1) .* exp(i * values(:, 2));
      avgCValue = mean(cValues);
      avgPeak = [freq, abs(avgCValue), angle(avgCValue)];
      avgPeaksCh = [avgPeaksCh; avgPeak];
    endif
  endfor
endfunction