function result = calibrate(buffer, fs, deviceName, extraCircuit, restart)
  persistent calBuffer = []; 
  persistent channelCnt = columns(buffer);
  % consts
  persistent FUND_PEAKS_ID = 1;
  persistent DISTORT_PEAKS_ID = 2;
  persistent RUNS = 10;
  persistent runPeaks = cell(2, RUNS, channelCnt);
  persistent runID = 0;
  global NOT_FINISHED_RESULT;
    
  calibrationSize = fs; % 1 second

  if (restart)
    calBuffer = [];
  endif

  calBuffer = [calBuffer; buffer];
  currentSize = rows(calBuffer);
  if (currentSize < calibrationSize)
    % not enough data, copying whole buffer
    
    % not finished    
    result = NOT_FINISHED_RESULT;
    runID = 0;
  else
    runID += 1;
    printf('Measuring calibration peaks for run ID %d\n', runID);    
    % purging old samples from analysis buffer to cut calBuffer to calibrationSize     
    calBuffer = calBuffer(currentSize - calibrationSize + 1: end, :);

    % calculate FFT peaks
    [fundPeaks, distortPeaks] = getHarmonics(calBuffer, fs);
    for channelID = 1:channelCnt
      % shift distortPeaks to zero time of fundPeaks and store to runPeaks
      fundPeaksCh = fundPeaks{channelID};
      distortPeaksCh = distortPeaks{channelID};
      if hasAnyPeak(fundPeaksCh) && hasAnyPeak(distortPeaksCh)
        % time shift distortPeaks to zero phase of fundPeaks        
        distortPeaksCh = phasesAtZeroTimeCh(fundPeaksCh, distortPeaksCh);
        % now distortPeaksCh are zero-time based. Phases in fundPeaksCh must be kept for storing into calfile!
      endif
      % store peaks of this run to persistent variable
      runPeaks{FUND_PEAKS_ID, runID, channelID} = fundPeaksCh;
      runPeaks{DISTORT_PEAKS_ID, runID, channelID} = distortPeaksCh;      
    endfor
    
    if runID < RUNS
      % not finished
      result = NOT_FINISHED_RESULT;
    else      
      % enough runs, calibrating
      printf('Enough runs, calibrating with measured peaks\n'); 
      timestamp = time();

      % storing joint directions cal file
      % each channel stored separately      
      for channelID = 1:channelCnt
        % determine peaks from runs
        [fundPeaksCh, distortPeaksCh] = detAveragePeaks(runPeaks, channelID)
        if hasAnyPeak(fundPeaksCh) && hasAnyPeak(distortPeaksCh)
          saveCalFile(fundPeaksCh, distortPeaksCh, fs, channelID, timestamp, deviceName, extraCircuit);
        elseif ~hasAnyPeak(fundPeaksCh) 
          printf('No fundaments found for channel ID %d, not storing its calibration file\n', channelID);
        else
          printf('No distortion peaks found for channel ID %d, not storing its calibration file\n', channelID);
        endif
      endfor
      % reset runID for next time
      runID = 0;
      global FINISHED_RESULT;
      result = FINISHED_RESULT;
    endif
  endif
endfunction

% avgaging fundPeaks amplitude, distortPeaks all for each frequency
function [avgFundPeaksCh, avgDistortPeaksCh] = detAveragePeaks(runPeaks, channelID)
  %consts
  persistent FUND_PEAKS_ID = 1;
  persistent DISTORT_PEAKS_ID = 2;
  
  avgFundPeaksCh = [];
  allFundPeaksCh = [];
  avgDistortPeaksCh = [];
  allDistortPeaksCh = [];

  % TODO solve changed freqs during calibration!!!!
  
  for runID = 1 : size(runPeaks, 2)
    % fundPeaks first
    fundPeaksCh = runPeaks{FUND_PEAKS_ID, runID, channelID};
    allFundPeaksCh = [allFundPeaksCh; fundPeaksCh];
    distortPeaksCh = runPeaks{DISTORT_PEAKS_ID, runID, channelID};
    allDistortPeaksCh = [allDistortPeaksCh; distortPeaksCh];
  endfor
  
  % calculate only if some fund and distort peaks are found
  if hasAnyPeak(allFundPeaksCh)
    avgFundPeaksCh = calculateAvgPeaks(allFundPeaksCh);
  endif
  if hasAnyPeak(allDistortPeaksCh)
    avgDistortPeaksCh = calculateAvgPeaks(allDistortPeaksCh);  
  endif
endfunction

% return average peaks for each frequency found in allPeaksCh
function avgPeaksCh = calculateAvgPeaks(allPeaksCh);
  avgPeaksCh = [];
  
  uniqFreqs = unique(allPeaksCh(:, 1));
  uniqFreqs = sort(uniqFreqs);
  % average for each freq
  for freq = transpose(uniqFreqs)
    % only for nonzero freqs
    if (freq > 0)
      freqIDs = find(allPeaksCh(:, 1) == freq);
      % averaging requires complex values    
      freqValues = allPeaksCh(freqIDs, 2:3);
      freqCValues = freqValues(:, 1) .* exp(i * freqValues(:, 2));
      avgCValue = mean(freqCValues);
      avgPeak = [freq, abs(avgCValue), angle(avgCValue)];
      avgPeaksCh = [avgPeaksCh; avgPeak];
    endif
  endfor
endfunction