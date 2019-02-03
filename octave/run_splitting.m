% splitting joint calibration  to DAC and ADC contributions

% this preliminary calculation version holds for:
% calFileVD - LEFT (1) = direct, RIGHT (2) = voltage divider with gain = LP gain at fundamental freq (3kHz fixed now)
% calFileLP - LEFT = direct, RIGHT = LP filter (input - resistor 10k -RIGHT- capacitor 10nF - ground)

calFileVD = genDataPath(['cal_3000_FS48000_' jointDeviceName '.dat']);
calFileLP = genDataPath(['cal_3000_FS48000_' jointDeviceName '_filter.dat']);

load(calFileVD);
fundPeaksVD = calRec.fundPeaks;
distortPeaksVD = calRec.distortPeaks;

load(calFileLP);
fundPeaksLP = calRec.fundPeaks;
distortPeaksLP = calRec.distortPeaks;


% for 6kHz
% direct = left channel
directCh = 1;
% attenuated channel - right
attenCh = 2;

% attenuation of the R-divider relative to generated amplitude on D side!
gainVD = fundPeaksVD(1, 2, attenCh) / genAmpl;

fundAmplVD = fundPeaksVD(1, 2, attenCh);
fundPhaseVD = fundPeaksVD(1, 3, attenCh);
fundPhaseDirectVD = fundPeaksVD(1, 3, directCh);


fundPhaseDirectLP = fundPeaksLP(1, 3, directCh);

% loading filter params from transferFile - array transfers
load(transferFile);

cnt = 200;
fundF = fundPeaksVD(1, 1, 1);
t = linspace(0, (cnt - 1)/fs, cnt);

[fundLPGain, fundLPPhaseShift] = getTransferParams(transfers, fundF);


timeOffsetLPvsVD = (fundPhaseDirectLP - fundPhaseDirectVD)/(2 * pi * fundF);

distortPeaksACh = [];
distortPeaksDCh = [];

for distortID = 1:4
  harmID = distortID + 1;
  distortF = fundF * harmID;
  
  % R-divider params
  distortAmplVD = distortPeaksVD(distortID, 2, attenCh);
  distortPhaseVD = distortPeaksVD(distortID, 3, attenCh);

  % LP params
  distortAmplLP = distortPeaksLP(distortID, 2, attenCh);
  distortPhaseLP = distortPeaksLP(distortID, 3, attenCh);
  
  % measured values (generated from measured params)
  % eq 1
  % Dvd + Avd = VD, where D, A, VD are amplitude and phase (complex amplitude) for R-divider signal (measured at R-divider levels!)
  % VD levels!
  refVD = cos(2*pi * distortF * t + distortPhaseVD) * distortAmplVD;


  % eq 2
  % Dlp + Alp = LP where D, A, G are amplitude and phase (complex amplitude) for filter signal (measured at filter levels!)

  % offsetting LP phase to time of VD
  offsetDistortPhaseLP = distortPhaseLP - 2*pi * distortF * timeOffsetLPvsVD;
  % LP levels!
  refLP = cos(2*pi * distortF * t + offsetDistortPhaseLP) * distortAmplLP;

  % "known" values for fitting
  y = [refVD; refLP];

  
  [distortLPGain, distortLPPhaseShift] = getTransferParams(transfers, distortF);

  % AD harmonic phaseShift - caused by fundamental phase shift (i.e. fund * harmonic id)
  phaseShiftAByLP = fundLPPhaseShift * distortF/fundF;

  f = @(p, x) lpEqs(t, distortF, p(1), p(2), p(3), p(4), gainVD, distortLPGain, distortLPPhaseShift, fundLPGain, phaseShiftAByLP);
  % ampls half, phases zero
  init = [distortAmplVD/2; 0; distortAmplVD/2; 0];

  [p, model_values, cvg, outp] = nonlin_curvefit(f, init, t, y);


  [amplA, phaseA] = fixMeasuredAmplPhase(p(1), p(2));
  [amplD, phaseD] = fixMeasuredAmplPhase(p(3), p(4));


  distortPeaksACh = [distortPeaksACh; [distortF, amplA, phaseA]];
  distortPeaksDCh = [distortPeaksDCh; [distortF, amplD, phaseD]];
endfor

% building calfile peaks
if true
  fundPeaksACh = [fundF, fundAmplVD, fundPhaseVD];
  fundPeaksDCh = [fundF, genAmpl, fundPhaseVD];

  saveCalFile(fundPeaksACh, distortPeaksACh, fs, attenCh, time(), inputDeviceName);
else
  % TODO fixing for new saveCalFile
  % testing split of both-side peaks into each side - works OK for VD, but only partially for LP - investigate!!!
  distortPeaksA = distortPeaksLP;
  distortPeaksA(:, 2, :) *= 0.8;

  distortPeaksD = distortPeaksLP;
  distortPeaksD(:, 2, :) *= 0.2;

  saveCalFile(fundPeaksLP, distortPeaksA, fs, inputDeviceName);
  saveCalFile(fundPeaksLP, distortPeaksD, fs, outputDeviceName);
endif

% finished command splitting
cmdDoneID = cmdID;

cmd = {PASS};