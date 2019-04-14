function calculateSplitCal(fundFreq, fs, playAmpl, playChID, analysedRecChID, filterName)
  global COMP_TYPE_JOINT;
  persistent AMPL_IDX = 4;  % = index of fundAmpl1 in cal peaks row

  % voltage divider
  [peaksVDRow, distortVDFreqs] = loadCalRow(fundFreq, fs, COMP_TYPE_JOINT, playChID, analysedRecChID);
  % LP filter (input - resistor 10k -RIGHT- capacitor 10nF - ground)
  [peaksLPRow, distortLPFreqs] = loadCalRow(fundFreq, fs, COMP_TYPE_JOINT, playChID, analysedRecChID, filterName);


  fundAmplVD = peaksVDRow(1, AMPL_IDX);
  % attenuation of voltage divider relative to generated amplitude on D side!
  gainVD = fundAmplVD / playAmpl;

  [fundLPGain, fundLPPhaseShift] = detTransfer(fundFreq, peaksVDRow, peaksLPRow, playAmpl);


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
  % But at time = 0 on DA side => on LP side the phase would be fundLPPhaseShift. Therefore refLP must be shifted by this time delay since 0-based peaksLPRow corresponds to time = -fundLPPhaseShift  
  fundLPTimeOffset = fundLPPhaseShift/(2*pi*fundFreq);
  
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
    % distort params are zero-based which does not correspond to time = 0, the sine must be shifted by fundLPTimeOffset
    refLP = cos(2*pi * distortFreq * (t + fundLPTimeOffset) + distortPhaseLP) * distortAmplLP;

    % "known" values for fitting
    y = [refVD; refLP];

    [distortLPGain, distortLPPhaseShift] = detTransferFromCalFiles(distortFreq, fs, playAmpl, playChID, analysedRecChID, filterName);
    
    % AD harmonic phaseShift - caused by fundamental phase shift (i.e. fund * harmonic id)        
    phaseShiftAByLP = fundLPPhaseShift * N;

    f = @(p, x) vdlpEqs(t, distortFreq, p(1), p(2), p(3), p(4), gainVD, distortLPGain, distortLPPhaseShift, fundLPGain, phaseShiftAByLP);
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
  saveNewCalFile(fs, fundPeaksACh, distortPeaksACh, NA, analysedRecChID, COMP_TYPE_REC_SIDE, timestamp);

  % D-values
  global COMP_TYPE_PLAY_SIDE;
  saveNewCalFile(fs, fundPeaksDCh, distortPeaksDCh, NA, playChID, COMP_TYPE_PLAY_SIDE, timestamp);  
endfunction

function saveNewCalFile(fs, fundPeaksCh, distortPeaksCh, playChID, channelID, compType, timestamp)
  devSpecs = createCalFileDevSpecs(compType, playChID, channelID);
  calFile = genCalFilename(getFreqs(fundPeaksCh), fs, devSpecs, '');
  
  % always writing new file - delete first if exists
  deleteFile(calFile);  
  saveCalFile(fundPeaksCh, distortPeaksCh, fs, calFile, timestamp);
  writeLog('INFO', 'Saved calculated split calibration into %s', calFile);
endfunction

% of not found, returns empty
function distortPeak = getDistortPeakForFreq(freq, peaksRow, distortFreqs)
  persistent PEAKS_START_IDX = 6;
  % index of freq in distortFreqs
  freqID = find(distortFreqs == freq);
  if ~isempty(freqID)
    distortPeak = peaksRow(PEAKS_START_IDX + freqID - 1);
  else
    distortPeak = [];
  endif  
endfunction