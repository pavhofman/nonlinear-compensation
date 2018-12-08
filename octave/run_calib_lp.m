% calibration D / A

% cely tenhle vypocet je pro:
% calFileG - kalibrace pro LEFT = fullscale, RIGHT = odporovy delic se stejnym zeslabenim, jako filtr na fundamentu (3kHz)
% calFileLP - kalibrace pro LEFT = fullscale, RIGHT = odbocka filtru

% POZOR - ulozene parametry filtru ve filter.dat ma gain RIGHT (filtr) vuci LEFT (fullscale)
calFileRD = 'cal_3000_FS48000_rec8.dat';
calFileLP = 'cal_filter_3000_FS48000_rec8.dat';

load(calFileRD);
fundPeaksRD = calRec.fundPeaks;
distortPeaksRD = calRec.distortPeaks;

load(calFileLP);
fundPeaksLP = calRec.fundPeaks;
distortPeaksLP = calRec.distortPeaks;


% for 6kHz
% fullscale = left channel
fullScaleCh = 1;
% attenuated channel - right
attenCh = 2;

% attenuation of the R-divider
gainRD = fundPeaksRD(1, 2, attenCh) / fundPeaksRD(1, 2, fullScaleCh);

% R-divider params
amplRD = distortPeaksRD(1, 2, attenCh);
phaseRD = distortPeaksRD(1, 3, attenCh);

% LP params
amplLP = distortPeaksLP(1, 2, attenCh);
phaseLP = distortPeaksLP(1, 3, attenCh);

cnt = 200;
fundF = 3000;
% second harmonic for 3kHz
distortF = 6000;
t = linspace(0, (cnt - 1)/fs, cnt);

% measured values (generated from measured params)
% eq 1
% Drd + Ard = RD, where D, A, RD are amplitude and phase (complex amplitude) for R-divider signal (measured at R-divider levels!)
refRD = cos(2*pi * distortF * t + phaseRD) * amplRD;
% eq 2
% Dlp + Alp = LP where D, A, G are amplitude and phase (complex amplitude) for filter signal (measured at filter levels!)

% R-divider fundament and LP fundament levels are similar, but not same!!!
refLP = cos(2*pi * distortF * t + phaseLP) * amplLP;

y = [refRD; refLP];

% loading filter params from transferFile
transferFile = 'transf.dat';
load(transferFile);

for i = 1:rows(transfers)
  transfer = transfers(i);
  if (transfer.freq == fundF)
    gainLPAtFund = transfer.gain;
    phaseLPAtFund = transfer.phaseShift;
  elseif (transfer.freq == distortF)
    gainLPAtDistort = transfer.gain;
    phaseLPAtDistort = transfer.phaseShift;
  endif
endfor

% AD harmonic gain change - caused by fundamental attenuation at LP - phaseLPAtFund
gainAByLP = gainLPAtFund / gainRD;
% AD harmonic phaseShift - caused by fundamental phase shift
phaseAByLP = phaseLPAtFund * distortF/fundF;

f = @(p, x) lpEqs(t, distortF, p(1), p(2), p(3), p(4), gainRD, gainLPAtDistort, phaseLPAtDistort, gainAByLP, phaseAByLP);
% ampls half, phases zero
init = [amplRD/2; 0; amplRD/2; 0];  

[p, model_values, cvg, outp] = nonlin_curvefit (f, init, t, y);


[amplD, phaseD] = fixMeasuredAmplPhase(p(1), p(2));
[amplA, phaseA] = fixMeasuredAmplPhase(p(3), p(4));




status = PASS;