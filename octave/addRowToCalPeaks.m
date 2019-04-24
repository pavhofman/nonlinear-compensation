% adding row to calPeaks
% distortPeaksCh can be empty
function [calPeaks, distortFreqs, addedRowIDs] = addRowToCalPeaks(fundPeaksCh, distortPeaksCh, calPeaks, distortFreqs, timestamp)
  % calPeaks: time, fundPhaseDiff1, fundPhaseDiff2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  global AMPL_IDX;  % = index of fundAmpl1
  global PEAKS_START_IDX;
  % fund amplitude within +/- SAME_AMPL_TOL considered same
  global SAME_AMPL_TOL;
  
  % edge rows can be changed if new row min or max. The easiest way is removing them first and adding newly calculated at the end
  % remove edge extrapolation rows
  calPeaks(1, :) = [];
  calPeaks(end, :) = [];
  
  % get distortion peaks only
  allDPeaksC = calPeaks(:, PEAKS_START_IDX:end);
  
  % peak values: complex numbers. Missing/not measured: NA
    
  freqIDs = [];
  for rowID = 1:rows(distortPeaksCh)
    % find freq position in distortFreqs
    peakFreq = distortPeaksCh(rowID, 1);
    if (!any(distortFreqs == peakFreq))
      % did not find peakFreq in distortFreqs, adding + expanding peaks with NA      
      distortFreqs = [distortFreqs, peakFreq];
      % add column of NAs (values for this new freq are missing in the existing peak rows
      allDPeaksC = [allDPeaksC, NA(rows(allDPeaksC), 1)];
    endif
    freqID = find(distortFreqs == peakFreq);
    freqIDs = [freqIDs, freqID];
  endfor
  
  % prepare row of NA for each freq
  dPeaksC = NA(1, length(distortFreqs));
  % copy distortPeaksCh to position of corresponding frequency, rest will stay NA
  for rowID = 1: rows(distortPeaksCh)
    peak = distortPeaksCh(rowID, :);
    freqID = freqIDs(rowID);
    % store the complex value of peak at freqID position of dPeaksC
    dPeaksC(freqID) = peak(2) * exp(i * peak(3));
  endfor
  
  if ~isempty(allDPeaksC)
    % sorting allDPeaksC by freqs:
    % add peaks to end
    allDPeaksC = [allDPeaksC; dPeaksC];
    
    % add freqs to first row
    allDPeaksC = [distortFreqs; allDPeaksC];

    % sort all by first row
    % only sortrows available, must use transposition
    allDPeaksC = transpose(sortrows(transpose(allDPeaksC), 1));


    % recover sorted freqs, remove from allDPeaksC
    distortFreqs = allDPeaksC(1,:);
    allDPeaksC = allDPeaksC(2:end, :);
    
    % recover new peaks row sorted by frequency, remove from allDPeaksC (to be added later on)
    dPeaksC = allDPeaksC(end,:);
    allDPeaksC = allDPeaksC(1:end - 1, :);
    
    % put allDPeaksC back to calPeaks
    calPeaks = [calPeaks(:, 1:PEAKS_START_IDX - 1), allDPeaksC];
  endif
  
  % build new complPeak line
  complPeak = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC);

  % remove existing rows (if any) with amplitude within tolerance SAME_AMPL_TOL apart from fundAmpl1 - we have newer values
  newFundAmpl = fundPeaksCh(1, 2);
  upperLimit = newFundAmpl * SAME_AMPL_TOL;
  lowerLimit = newFundAmpl * (1/SAME_AMPL_TOL);
  sameRowIDs = find(calPeaks(:, AMPL_IDX) < upperLimit & calPeaks(:, AMPL_IDX) > lowerLimit);
  if ~isempty(sameRowIDs)
    writeLog('INFO', "Removing old close-amplitude rows IDs: %s", num2str(sameRowIDs));
    calPeaks(sameRowIDs, :) = [];
  endif
  
  
  % add the newly created row to the end
  calPeaks = [calPeaks; complPeak];
  
  % the removed row could create a frequency with all peaks unknown. Remove such columns
  knownIDs = ~isna(calPeaks);
  % number of known values in columns
  knownIDsCnt = sum(knownIDs, 1);
  % find columns with known == 0 , i.e. only the frequency
  zeroColIDs = find(knownIDsCnt == 0);
  if !isempty(zeroColIDs)
    % found index on all-NA collumn, remove from peaks and freqs
    calPeaks(:, zeroColIDs) = [];
    distortFreqs(:, zeroColIDs - PEAKS_START_IDX + 1) = [];
  endif
  
  % sort rows by fundAmpl1 (at position AMPL_IDX)
  calPeaks = sortrows(calPeaks, AMPL_IDX);
  
  % add fresh edge rows for extrapolation
  calPeaks = addEdgeCalPeaks(calPeaks);
  
  % HACK: addedRowIDs determined by its timestamp (incl. respective updated bordering edgeCalPeaks)
  % row-vector needed - transposing
  addedRowIDs = transpose(find(calPeaks(:, 1) == timestamp));
endfunction