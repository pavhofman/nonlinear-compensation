% fundPeaksCh have at least one freq (row), distortPeaksCh can be empty (clean signal or single-sine fundament > fs/4 (i.e. no higher harmonics)
function calFileStruct = saveCalFile(fundPeaksCh, distortPeaksCh, fs, channelID, timestamp, deviceName, extraCircuit = '')
  % remove zero freq rows from distortPeaksCh
  if ~isempty(distortPeaksCh)
    rowIDs = distortPeaksCh(:, 1) == 0;
    distortPeaksCh(rowIDs, :) = [];
  endif
  
  freqs =  getFreqs(fundPeaksCh);
  calFile = genCalFilename(freqs, fs, channelID, deviceName, extraCircuit);
  
  %% calFile line contains exactly 2 fundpeaks, therefore fundPeaksCh must contain so many rows!!
  fundPeaksCh = padWithZeros(fundPeaksCh, 2);
  
  if exist(calFile, 'file')
    load(calFile);
    calPeaks = calRec.peaks;
    distortFreqs = calRec.distortFreqs;
    [calPeaks, distortFreqs, addedRowIDs] = addRowToCalPeaks(fundPeaksCh, distortPeaksCh, calPeaks, distortFreqs, timestamp);    
  else
    if isempty(distortPeaksCh)
      % no distortions, only fund  peaks
      distortFreqs = [];
      dPeaksC = [];
    else
      distortFreqs = transpose(distortPeaksCh(:, 1));
      % build new/first complPeak line - convert peaks to complex numbers and transpose
      dPeaksC = transpose(distortPeaksCh(:, 2) .* exp(i * distortPeaksCh(:, 3)));
    endif
    calPeaks = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC);
    % adding edge rows for extrapolation
    calPeaks = addEdgeCalPeaks(calPeaks);
    % new calfile, always 3 rows
    addedRowIDs = 1:3;
  endif

  calRec.fundFreqs = transpose(fundPeaksCh(:, 1));
  calRec.distortFreqs = distortFreqs;
  calRec.peaks = calPeaks;
  writeLog('DEBUG', 'Updated (not stored yet) calRec for calfile %s: %s', calFile, disp(calRec));
  
  calFileStruct = struct();
  calFileStruct.fileName = calFile;
  calFileStruct.calRec = calRec;
  calFileStruct.addedRowIDs = addedRowIDs;
endfunction


% pad peaksCh with zero rows up to rowsCnt
function peaksCh = padWithZeros(peaksCh, rowsCnt)
  peaksCh = [peaksCh; zeros(rowsCnt - rows(peaksCh), 3)];
endfunction