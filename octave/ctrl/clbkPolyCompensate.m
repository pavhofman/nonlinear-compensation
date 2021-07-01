function clbkPolyCompensate(src, data, direction, cmdFile)
  global POLYCOMP;
  global chMode;
  global recInfo;
  global ANALYSED_CH_ID;
  global PLAY_CH_ID;
  global COMP_TYPE_JOINT;

  persistent PI2 = 2 * pi;

  FREQ = 911;

  fs = recInfo.fs;
  calFile = genCalFilename(FREQ, fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID, recInfo.playCalDevName, recInfo.recCalDevName, chMode);
  % loading calRec structure
  load(calFile);
  complAllPeaksCh = calRec.peaks;
  distortFreqsCh = calRec.distortFreqs;


  global AMPL_IDX;  % = index of fundAmpl1
  % column
  fundAmpls = complAllPeaksCh(:, AMPL_IDX);
  periods = 20;
  LINE_VALUES = 20;
  duration = periods/FREQ;
  totalCnt = fs * duration;
  t = transpose(linspace(0, duration, totalCnt));
  allHarmDistortWaves =[];
  firstRun = true;
  maxHarmID = min(floor(fs/(2*FREQ)), 7);
  writeLog('DEBUG', 'Addding max. %d harmonics', maxHarmID);
  for harmID = 2:maxHarmID
      distortFreq = harmID * FREQ;
      % column
      distortPeaks = getDistortPeaksForFreq(distortFreq, complAllPeaksCh, distortFreqsCh);
      if (isempty(distortPeaks))
        continue;
      end

      distortAmpls = abs(distortPeaks);
      distortPhases = angle(distortPeaks) - pi;

      distortWaves = cos(PI2 * distortFreq * t + distortPhases') .* distortAmpls';
      % adding to allHarmDistortWaves
      if firstRun
        allHarmDistortWaves = distortWaves;
        firstRun = false;
      else
        % adding harmonics
        allHarmDistortWaves += distortWaves;
      end
  end
  % turning to single row
  %allHarmDistortWaves = allHarmDistortWaves(:, end);
  allHarmDistortWaves = vec(allHarmDistortWaves);
  % fundamentals are at zero phases
  cleanWaves = cos(PI2 * FREQ * t) .* fundAmpls';
  % turning to single row

  %cleanWaves = cleanWaves(:, end);
  cleanWaves = vec(cleanWaves);

  dirtyWaves = cleanWaves + allHarmDistortWaves;

  % adding values to -1/+1
  cleanBottom = linspace(-1, min(cleanWaves), LINE_VALUES)';
  cleanTop = linspace(max(cleanWaves), 1, LINE_VALUES)';
  fullCleanWaves = [cleanBottom; cleanWaves;  cleanTop];

  dirtyBottom = linspace(-1, min(dirtyWaves), LINE_VALUES)';
  dirtyTop = linspace(max(dirtyWaves), 1, LINE_VALUES)';
  fullDirtyWaves = [dirtyBottom; dirtyWaves; dirtyTop];

  % finding piecewise polynomial converting distorted to clean
  %pp = polyfit(fullCleanWaves, fullDirtyWaves, 7);

  % breaks from -1 to 1;
  midBreaks = linspace(min(cleanWaves), max(cleanWaves), 20)';
  breaks = [-1; midBreaks; 1];

  % constraints: values [-1, -1], [1, 1], derivative [-1, 1], [1, 1]
  xc = [-1, min(cleanWaves), max(cleanWaves), 1];
  yc = [-1, min(dirtyWaves), max(dirtyWaves), 1];
  cc = [1, 1, 1, 1];
  con = struct ("xc", xc, "yc", yc, "cc", cc);

  pp = splinefit(fullCleanWaves, fullDirtyWaves, breaks, "constraints", con, "order", 3);
  x = -max(breaks):0.01:max(breaks);
  figure(9);
  MAGNIFICATION = 3e4;
  plot(x, x, '.b', x, x + MAGNIFICATION*(ppval(pp, x) - x), 'r', fullCleanWaves, fullCleanWaves + MAGNIFICATION*(fullDirtyWaves - fullCleanWaves), '*g', "markersize", 5, breaks, breaks, 'k+', "markersize", 15), grid on;
  l = legend('no distortion', sprintf('polynomials, %dM zoomed', MAGNIFICATION/1000000), sprintf('pre-distorted samples, %dM zoomed', MAGNIFICATION/1000000), 'polynomials breaks');
  legend(l, 'location', 'southeast');
  set(l, "fontsize", 12);
  %plot(cleanWaves, cleanWaves + 30000*(dirtyWaves - cleanWaves), breaks, breaks, 'k+', "markersize", 10), grid on;
  ser = var2bytea(pp);
  % base64_xxx works only with doubles
  ppStr = base64_encode(double(ser));

  cmd = sprintf('%s %s', POLYCOMP, ppStr);
  writeCmd(cmd, cmdFile);
end

