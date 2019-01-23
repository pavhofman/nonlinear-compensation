% both fundPeaksCh and distortPeaksCh have at least one freq (row)!!
function result = saveCalFile(fundPeaksCh, distortPeaksCh, fs, channelID, timestamp, deviceName, extraCircuit = '')
  % consts
  persistent maxFundPeaksCnt = getMaxFundPeaksCnt();
  % remove zero freq rows from distortPeaksCh
  rowIDs = distortPeaksCh(:, 1) == 0;
  distortPeaksCh(rowIDs, :) = [];
  
  freqs =  getFreqs(fundPeaksCh);
  calFile = genCalFilename(freqs, fs, channelID, deviceName, extraCircuit);
  
  %% calFile line contains maxFundPeaksCnt values, therefore fundPeaksCh must contain so many rows!!
  fundPeaksCh = padWithZeros(fundPeaksCh, maxFundPeaksCnt);
  
  if exist(calFile, 'file')
    load(calFile);
    complAllPeaks = calRec.distortPeaks;
    distortFreqs = calRec.distortFreqs;
    [complAllPeaks, distortFreqs] = addRow(fundPeaksCh, distortPeaksCh, complAllPeaks, distortFreqs, timestamp);
  else        
    distortFreqs = transpose(distortPeaksCh(:, 1));
    % build new/first complPeak line - convert peaks to complex numbers and transpose
    peaksC = transpose(distortPeaksCh(:, 2) .* exp(i * distortPeaksCh(:, 3)));
    complAllPeaks = buildComplPeakRow(timestamp, fundPeaksCh, peaksC);
    % adding edge rows for extrapolation
    complAllPeaks = addExtrapolRows(complAllPeaks);
  endif

  calRec.fundFreqs = transpose(fundPeaksCh(:, 1));
  calRec.distortFreqs = distortFreqs;
  calRec.distortPeaks = complAllPeaks;
  
  disp(calRec);
  save(calFile, 'calRec');
  printf('Saved calfile %s\n', calFile);
  global FINISHED_RESULT;
  result = FINISHED_RESULT;
endfunction

function [complAllPeaks, distortFreqs] = addRow(fundPeaksCh, distortPeaksCh, complAllPeaks, distortFreqs, timestamp)
  % complAllPeaks: time, origFundPhase1, origFundPhase2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
  persistent PEAKS_START_IDX = 6;
  
  % edge rows can be changed if new row min or max. The easiest way is removing them first and adding newly calculated at the end
  % remove edge extrapolation rows
  complAllPeaks(1, :) = [];
  complAllPeaks(end, :) = [];
  
  % get peaks only
  allPeaks = complAllPeaks(:, PEAKS_START_IDX:end);
  
  % peak values: complex numbers. Missing/not measured: NA
  freqIDs = [];
  for rowID = 1:rows(distortPeaksCh)
    % find freq position in distortFreqs
    peakFreq = distortPeaksCh(rowID, 1);
    if (!any(distortFreqs == peakFreq))
      % did not find peakFreq in distortFreqs, adding + expanding peaks with NA      
      distortFreqs = [distortFreqs, peakFreq];
      % add column of NAs (values for this new freq are missing in the existing peak rows
      allPeaks = [allPeaks, NA(rows(allPeaks), 1)];
    endif
    freqID = find(distortFreqs == peakFreq);
    freqIDs = [freqIDs, freqID];
  endfor
  
  % prepare row of NA for each freq
  peaksC = NA(1, length(distortFreqs));
  % copy distortPeaksCh to position of corresponding frequency, rest will stay NA
  for rowID = 1: rows(distortPeaksCh)
    peak = distortPeaksCh(rowID, :);
    freqID = freqIDs(rowID);
    % store the complex value of peak at freqID position of peaksC
    peaksC(freqID) = peak(2) * exp(i * peak(3));
  endfor
  
  % sorting allPeaks by freqs:
  % add peaks to end
  allPeaks = [allPeaks; peaksC];
  
  % add freqs to first row
  allPeaks = [distortFreqs; allPeaks];

  % sort all by first row
  % only sortrows available, must use transposition
  allPeaks = transpose(sortrows(transpose(allPeaks), 1));

  % recover sorted freqs, remove from allPeaks
  distortFreqs = allPeaks(1,:);
  allPeaks = allPeaks(2:end, :);
  
  % recover new peaks row sorted by frequency, remove from allPeaks (to be added later on)
  peaksC = allPeaks(end,:);
  allPeaks = allPeaks(1:end - 1, :);
  
  % put allPeaks back to complAllPeaks
  complAllPeaks = [complAllPeaks(:, 1:PEAKS_START_IDX - 1), allPeaks];
  
  % build new complPeak line
  complPeak = buildComplPeakRow(timestamp, fundPeaksCh, peaksC);

  % remove any existing row (if exists) with amplitude equal to fundAmpl1 from complAllPeaks since we have newer values
  newFundAmpl = fundPeaksCh(1, 2);
  rowIDs = find(complAllPeaks(:, AMPL_IDX) == newFundAmpl);
  complAllPeaks(rowIDs, :) = [];
  
  
  % add the newly created row to the end
  complAllPeaks = [complAllPeaks; complPeak];
  
  % the removed row could create a frequency with all peaks unknown. Remove such columns
  knownIDs = ~isna(complAllPeaks);
  % number of known values in columns
  knownIDsCnt = sum(knownIDs, 1);
  % find columns with known == 0 , i.e. only the frequency
  zeroColIDs = find(knownIDsCnt == 0);
  if !isempty(zeroColIDs)
    % found index on all-NA collumn, remove from peaks and freqs
    complAllPeaks(:, zeroColIDs) = [];
    distortFreqs(:, zeroColIDs - PEAKS_START_IDX) = [];
  endif
  
  % sort rows by fundAmpl1 (at position AMPL_IDX)
  complAllPeaks = sortrows(complAllPeaks, AMPL_IDX);
  
  % add fresh edge rows for extrapolation
  complAllPeaks = addExtrapolRows(complAllPeaks);
endfunction

function complPeak = buildComplPeakRow(timestamp, fundPeaksCh, peaks)
  % build new complPeak line
  origFundPhases = fundPeaksCh(:, 3);
  fundAmpls = fundPeaksCh(:, 2);
  complPeak = [timestamp, transpose(origFundPhases), transpose(fundAmpls), peaks];
endfunction

function complAllPeaks = addExtrapolRows(complAllPeaks)
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
  persistent PEAKS_START_IDX = 6;
  
  % complAllPeaks must be are sorted by fundAmpl!

  % get peaks only
  allPeaks = complAllPeaks(:, PEAKS_START_IDX:end);

  % add first row - zero ampl peaks for <0, minLevel> extrapolation
  % each peak has aplitude -> zero and phase same as minLevel (i.e. first row)
  
  % finding existing peaks from minimum
  peaks = getEdgePeaks(allPeaks, 1:rows(complAllPeaks));
  % phase must be preserved, therefore ampl cannot not be 0 => 1e-15 is almost zero
  zeroPeaks = 1e-15 * exp(i * angle(peaks));

  % max level - same phase as maxLevel (last row), amplitude = scaled to fundAmpl = 1
  peaks = getEdgePeaks(allPeaks, flip(1:rows(complAllPeaks)));
  ampls = abs(peaks);
  phases = angle(peaks);
  fundAmpl = complAllPeaks(end, AMPL_IDX);
  scaleToOne = 1/fundAmpl;
  onePeaks =  scaleToOne * ampls .* exp(i * phases);
  
  zeroAmpls= [0, 0];
  % only freq1
  oneAmpls= [1, 0];

  complZeroPeaks = [complAllPeaks(1, 1 : AMPL_IDX - 1), zeroAmpls, zeroPeaks];
  complOnePeaks = [complAllPeaks(1, 1 : AMPL_IDX - 1), oneAmpls, onePeaks];
  complAllPeaks = [complZeroPeaks; complAllPeaks; complOnePeaks];  
endfunction

% create row of edge peaks, first non-NA peak for each distortFreq, in the order of rowIDs (used for finding minimum as well as maximum)
function peaks = getEdgePeaks(allPeaks, rowIDs)
  peaks = [];
  % for each distortfreq
  for colID = 1:columns(allPeaks)
    peak = NA;
    for rowID = rowIDs
      thisPeak = allPeaks(rowID, colID);
      if ~isna(thisPeak)
        % found
        peak = thisPeak;
        break;
      endif      
    endfor
    % did not find any peak, weird!
    if isna(peak)
      printf('Did not find any existing edge peak, using NA\n');
      peak = NA;
    endif
    % adding
    peaks = [peaks, peak];
  endfor
endfunction


% pad peaksCh with zero rows up to rowsCnt
function peaksCh = padWithZeros(peaksCh, rowsCnt)
  peaksCh = [peaksCh; zeros(rowsCnt - rows(peaksCh), 3)];
endfunction