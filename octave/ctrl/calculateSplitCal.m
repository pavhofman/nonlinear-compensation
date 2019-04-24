function calculateSplitCal(fundFreq, fs, playAmpl, playChID, analysedRecChID, chMode, vdName, lpName)
  global COMP_TYPE_JOINT;
  global AMPL_IDX;  % = index of fundAmpl1 in cal peaks row

  % voltage divider
  [peaksVDRow, distortVDFreqs] = loadCalRow(fundFreq, fs, COMP_TYPE_JOINT, playChID, analysedRecChID, chMode, vdName);
  % LP filter (input - resistor 10k -RIGHT- capacitor 10nF - ground)
  [peaksLPRow, distortLPFreqs] = loadCalRow(fundFreq, fs, COMP_TYPE_JOINT, playChID, analysedRecChID, chMode, lpName);


  fundAmplVD = peaksVDRow(1, AMPL_IDX);

  % fundXXGain - attenuation of voltage divider relative to generated amplitude on D side!
  % fundXXPhaseShift - phaseshift between analysed channel and direct channel
  [fundVDGain, fundVDPhaseShift] = detTransfer(peaksVDRow, playAmpl);
  [fundLPGain, fundLPPhaseShift] = detTransfer(peaksLPRow, playAmpl);


  % length of time series for nonlin_curvefit
  % 1 period for 100Hz, for now
  cnt = floor(fs/100);
  t = linspace(0, (cnt - 1)/fs, cnt);

  distortPeaksACh = [];
  distortPeaksDCh = [];
  
  % starting with second harmonic
  distortFreq = 2 * fundFreq;
  
  % VD and LP equations solve for the same DA/AD distortions. Same means they must be the the same time.
  % VD: time on AD side = time on DA side (no phaseShift considered). 
  % LP: LP is calculated for time = 0 (fundPhase = 0 - peaksLPRow has time moved to zero phase by calibration).
  % But at time = 0 on DA side => on LP side the phase would be shifted. 
  % Therefore refLP must be shifted by this time delay since 0-based peaksLPRow corresponds to time corresponding to this phase shift.
  % All we have are phase shifts of analyzed channel vs. direct channel. This phase shift for VD is not zero - there are differences between the two channels
  % We need phase shift between LP and VD. Therefore we must subtract the interchannel difference (fundVDPhaseShift) to get plain VD phaseshift
  
  fundLPvsVDPhaseShift = fundLPPhaseShift - fundVDPhaseShift;
  fundLPvsVDTimeOffset = (fundLPvsVDPhaseShift)/(2*pi*fundFreq);
  
  while distortFreq < fs/2
    N = distortFreq/ fundFreq;
    % only freqs available for LP and VD can be calculated
    % TODO - skipping missing distortFreqs in LP/VD rows!
    distortPeakVD = getDistortPeakForFreq(distortFreq, peaksVDRow, distortVDFreqs);
    distortPeakLP = getDistortPeakForFreq(distortFreq, peaksLPRow, distortLPFreqs);
    
    if isempty(distortPeakVD) || isempty(distortPeakLP)
      % some distortPeaks at curFreq unknown, skipping this curFreq
      distortFreq += fundFreq;
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
    % Dvd + Avd = VD, where D, A, VD are amplitude and phase (complex amplitude) for R-divider signal (measured at R-divider levels!)
    % VD levels!
    refVD = cos(2*pi * distortFreq * t + distortPhaseVD) * distortAmplVD;


    % eq 2
    % Dlp + Alp = LP where D, A, G are amplitude and phase (complex amplitude) for filter signal (measured at filter levels!)
    
    % LP levels!
    % distort params are zero-based which does not correspond to time = 0, the sine must be shifted by fundLPvsVDTimeOffset
    refLP = cos(2*pi * distortFreq * (t + fundLPvsVDTimeOffset) + distortPhaseLP) * distortAmplLP;

    % "known" values for fitting
    y = [refVD; refLP];

    [distortVDGain, distortVDPhaseShift] = detTransferFromCalFile(distortFreq, fs, playAmpl, playChID, analysedRecChID, chMode, vdName);
    [distortLPGain, distortLPPhaseShift] = detTransferFromCalFile(distortFreq, fs, playAmpl, playChID, analysedRecChID, chMode, lpName);
    distortLPvsVDPhaseShift = distortLPPhaseShift - distortVDPhaseShift;
    
    
    % AD harmonic phaseShift - caused by fundamental phase shift (i.e. fund * harmonic id)        
    phaseShiftAByLPvsVD = fundLPvsVDPhaseShift * N;

    f = @(p, x) vdlpEqs(t, distortFreq, p(1), p(2), p(3), p(4), fundVDGain, fundLPGain, distortVDGain, distortLPGain, distortLPvsVDPhaseShift, phaseShiftAByLPvsVD);
    % ampls half, phases zero
    init = [distortAmplVD/2; 0; distortAmplVD/2; 0];

    [p, model_values, cvg, outp] = nonlin_curvefit(f, init, t, y);


    [amplA, phaseA] = fixMeasuredAmplPhase(p(1), p(2));
    [amplD, phaseD] = fixMeasuredAmplPhase(p(3), p(4));


    distortPeaksACh = [distortPeaksACh; [distortFreq, amplA, phaseA]];
    distortPeaksDCh = [distortPeaksDCh; [distortFreq, amplD, phaseD]];
    
    distortFreq += fundFreq;
  endwhile

  % building calfile peaks
  fundPeaksACh = [fundFreq, fundAmplVD, 0];
  fundPeaksDCh = [fundFreq, playAmpl, 0];


  % storing to calFiles
  timestamp = time();
  
  % A-values
  global COMP_TYPE_REC_SIDE;
  saveNewCalFile(fs, fundPeaksACh, distortPeaksACh, NA, analysedRecChID, chMode, COMP_TYPE_REC_SIDE, timestamp);

  % D-values
  global COMP_TYPE_PLAY_SIDE;
  saveNewCalFile(fs, fundPeaksDCh, distortPeaksDCh, NA, playChID, chMode, COMP_TYPE_PLAY_SIDE, timestamp);  
endfunction

function saveNewCalFile(fs, fundPeaksCh, distortPeaksCh, playChID, channelID, chMode, compType, timestamp)
  % no extraCircuit
  calFile = genCalFilename(getFreqs(fundPeaksCh), fs, compType, playChID, channelID, chMode, '');
  
  % always writing new file - delete first if exists
  deleteFile(calFile);  
  saveCalFile(fundPeaksCh, distortPeaksCh, fs, calFile, timestamp);
  writeLog('INFO', 'Saved calculated split calibration into %s', calFile);
endfunction

% of not found, returns empty
function distortPeak = getDistortPeakForFreq(freq, peaksRow, distortFreqs)
  global PEAKS_START_IDX;
  % index of freq in distortFreqs
  freqID = find(distortFreqs == freq);
  if ~isempty(freqID)
    distortPeak = peaksRow(PEAKS_START_IDX + freqID - 1);
  else
    distortPeak = [];
  endif  
endfunction