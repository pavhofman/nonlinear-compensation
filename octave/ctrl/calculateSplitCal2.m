function calculateSplitCal2(fundFreq, fs, playChID, analysedRecChID, chMode, vdName, lpName, nonInteger)
  global COMP_TYPE_JOINT;
  global AMPL_IDX;  % = index of fundAmpl1 in cal peaks row
  global PLAY_AMPL_IDX;  % = index of playAmpl1 in cal peaks row
  global EXTRA_TRANSFER_DIR;
  
  persistent PI2 = 2*pi;

  % voltage divider
  calFile = genCalFilename(fundFreq, fs, COMP_TYPE_JOINT, playChID, analysedRecChID, chMode, vdName);
  [peaksVDRow, distortVDFreqs] = loadCalRow(calFile);
  % LP filter (input - resistor 10k -RIGHT- capacitor 10nF - ground)
  calFile = genCalFilename(fundFreq, fs, COMP_TYPE_JOINT, playChID, analysedRecChID, chMode, lpName);
  [peaksLPRow, distortLPFreqs] = loadCalRow(calFile);


  fundAmplVD = peaksVDRow(1, AMPL_IDX);
  % both VD and LP peaks must have been measured with the same play amplitude!
  playAmpl = peaksVDRow(1, PLAY_AMPL_IDX);

  % fundGainXX - attenuation of voltage divider (measured amplitude on A side / generated amplitude on D side)
  % fundPhaseShiftXX - phaseshift between direct channel and analysed channel
  [fundGainVD, fundPhaseShiftVD] = detTransfer(peaksVDRow);
  [fundGainLP, fundPhaseShiftLP] = detTransfer(peaksLPRow);


  % length of time series for nonlin_curvefit
  % 5 fundamental periods, approx 200 numbers per period, times not at boundary of each period (1001/5=200.2)
  periods = 5;
  totalCnt = 1001;
  t = linspace(0, periods/fundFreq, totalCnt);

  distortPeaksACh = [];
  distortPeaksDCh = [];
  
  % starting with second harmonic, to transferFreqs size
  maxN = length(getTransferFreqs(fundFreq, fs, nonInteger));

  for N = 2 : maxN
    distortFreq = N * fundFreq;
    % only freqs available for LP and VD can be calculated
    % TODO - skipping missing distortFreqs in LP/VD rows!
    distortPeakVD = getDistortPeakForFreq(distortFreq, peaksVDRow, distortVDFreqs);
    distortPeakLP = getDistortPeakForFreq(distortFreq, peaksLPRow, distortLPFreqs);
    
    if isempty(distortPeakVD) || isempty(distortPeakLP)
      % some distortPeaks at curFreq unknown, skipping this curFreq
      continue;
    end
    
    % VD params
    distortAmplVD = abs(distortPeakVD);
    distortPhaseVD = angle(distortPeakVD);

    % LP params
    distortAmplLP = abs(distortPeakLP);
    distortPhaseLP = angle(distortPeakLP);
  
    % measured values (generated from measured params)
    % eq 1
    % Dvd + Avd = VD, where D, A, VD are amplitude and phase (complex amplitude) for VD signal (measured at VD levels)
    refVD = distortAmplVD * cos(PI2 * distortFreq * t + distortPhaseVD);


    % eq 2
    % Dlp + Alp = LP where D, A, G are amplitude and phase (complex amplitude) for filter signal (measured at filter levels)
    refLP = distortAmplLP * cos(PI2 * distortFreq * t + distortPhaseLP);

    % "known" values for fitting
    y = [refVD; refLP];

    [distortGainVD, distortPhaseShiftVD] = detTransferFromTransferFile(distortFreq, vdName);
    [distortGainLP, distortPhaseShiftLP] = detTransferFromTransferFile(distortFreq, lpName);
    
    % VD and LP equations solve for the same DA/AD distortions. Same means they must be at the same time.
    % The measured values loaded from cal files are on AD side and zero-time based (time-shifted to zero fundamental phase)
    % At time = 0 on ADC side => the DAC side phase shift of every n-th harmonic (incl. the fundamental) is preceeding by the n-th multiple of the filter phase shift at fundamental
    phaseShiftByFundVD = N * fundPhaseShiftVD;
    phaseShiftByFundLP = N * fundPhaseShiftLP;
    
    f = @(p, x) vdlpEqs2(t, distortFreq, p(1), p(2), p(3), p(4), fundGainVD, fundGainLP, distortGainVD, distortGainLP, distortPhaseShiftVD, distortPhaseShiftLP, phaseShiftByFundVD, phaseShiftByFundLP);
    % ampls half, phases zero
    init = [distortAmplVD/2; 0; distortAmplVD/2; 0];
    [p, model_values, cvg, outp] = nonlin_curvefit(f, init, t, y);

    [amplA, phaseA] = fixMeasuredAmplPhase(p(1), p(2));
    [amplD, phaseD] = fixMeasuredAmplPhase(p(3), p(4));


    distortPeaksACh = [distortPeaksACh; [distortFreq, amplA, phaseA]];
    distortPeaksDCh = [distortPeaksDCh; [distortFreq, amplD, phaseD]];
  endfor

  % building calfile peaks
  fundPeaksACh = [fundFreq, fundAmplVD, 0];
  fundPeaksDCh = [fundFreq, playAmpl, 0];


  % storing to calFiles
  timestamp = time();
  
  % ADC values
  % storing ADC values disabled, capture-side only calibration of ADC is used instead
  %global COMP_TYPE_REC_SIDE;
  %saveNewCalFile(fs, fundPeaksACh, distortPeaksACh, NA, analysedRecChID, chMode, COMP_TYPE_REC_SIDE, timestamp);

  % DAC values
  global COMP_TYPE_PLAY_SIDE;
  saveNewCalFile(fs, fundPeaksDCh, distortPeaksDCh, NA, playChID, chMode, COMP_TYPE_PLAY_SIDE, timestamp);  
endfunction

function saveNewCalFile(fs, fundPeaksCh, distortPeaksCh, playChID, channelID, chMode, compType, timestamp)
  % no extraCircuit
  calFile = genCalFilename(getFreqs(fundPeaksCh), fs, compType, playChID, channelID, chMode, '');
  
  % always writing new file - delete first if exists
  deleteFile(calFile);  
  saveCalFile(fundPeaksCh, distortPeaksCh, fs, calFile, NA, timestamp);
  writeLog('INFO', 'Saved calculated split calibration into %s', calFile);
endfunction

% of not found, returns empty
function distortPeak = getDistortPeakForFreq(freq, peaksRow, distortFreqs)
  global PEAKS_START_IDX;
  % index of freq in distortFreqs
  % support for nonInteger freqs
  freqID = find(round(distortFreqs) == round(freq));
  if ~isempty(freqID)
    distortPeak = peaksRow(PEAKS_START_IDX + freqID - 1);
  else
    distortPeak = [];
  endif  
endfunction