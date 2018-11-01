function plotPhase(recorded, fs, measfreq, refGain, phaseShift, ys, bins)
  f = linspace(1, fs/2, bins);

  % plotting abs(fft)
  subplot(4,1,1);
  stem(f,abs(ys));
  xlabel 'Frequency (Hz)';
  ylabel '|y|';
  grid;

  % We want to see ys maximum. We do it by zeroing all ys under certain level (note - we did not normalize, raw numbers!)
  % TODO - this procedure needs more robustness
  yslimit = 10;
  ys(abs(ys) < yslimit) = 0;
  phs = angle(ys);

  % plotting phase(fft)
  subplot(4,1,2);
  stem(f,phs/pi)
  xlabel 'Frequency (Hz)';
  ylabel 'Phase / \pi';
  grid;

  % plotting phase alignment of calculated reference sine and recorded at the end of the array

  % generating the reference sine
  t = 0:1/fs:length(recorded)/fs;
  t = t(1:length(recorded))';
  reference = cos(2*pi * measfreq * t + phaseShift)* refGain;

  % finding end of arrays
  samplesPlotted = 1000;
  endPos = length(recorded);
  % align to have a nice graph
  endPos = endPos - mod(endPos, samplesPlotted);
  lowT = endPos - samplesPlotted;
  highT = endPos;

  % the curves must be exactly phase-aligned!!!
  subplot(4,1,3);
  plot(
    (lowT:highT), recorded(lowT:highT), "-.b",
    (lowT:highT), reference(lowT:highT), "--r"
  );
  title 'Recorded (blue) ; Reference (red)';

  subplot(4,1,4);
  plot(
    (lowT:highT), recorded(lowT:highT)-reference(lowT:highT)
  );
  title 'Difference (recorded - reference)';
endfunction
