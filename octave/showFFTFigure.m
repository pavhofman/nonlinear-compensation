function showFFTFigure(samples, fs)
  persistent fftFigure = 0;
  persistent fftLine = [];
  persistent fftSize = 0;
  persistent fftFs = 0;
  persistent winfun;
  persistent winmean;
  persistent yavg;
  persistent yavgn;
  persistent sampleBuffer = [];
  global showFFTFigureConfig;

  if fftFigure == 0
    fftFigure = figure;
    fftAxes = axes('parent', fftFigure, 'xlimmode', 'manual', 'ylimmode', 'manual', 'xscale', 'log', 'yscale', 'linear', 'xlim', [10 fs/2], 'ylim', [-150, 0]);
    xlabel('Frequency (Hz)', 'fontsize', 10);
    ylabel('Magnitude (dB)', 'fontsize', 10);
    % change the tick labels of the graph from scientific notation to floating point:
    xt = get(gca,'XTick');
    set(gca,'XTickLabel', sprintf('%.0f|',xt))
    addlistener(gca, 'xlim', @logXTickZoomHandler)
  end
  if (showFFTFigureConfig.fftSize != fftSize) ...
      || (fs != fftFs)
    fftFs = fs;
    fftSize = showFFTFigureConfig.fftSize;
    fftXAxisData = (0 : (fftSize / 2)) * fs / fftSize;
    colors = {'red';'blue'};
    for i=1:length(colors)
        if (i <= length(fftLine)) && ishandle(fftLine(i))
            delete(fftLine(i))
        end
        fftLine(i) = line(
                'XData', fftXAxisData,
                'YData', ones(1, fftSize/2 + 1),
                'Color', char(colors(i)));
    end
    winfun = hanning(fftSize);
    winmean = mean(winfun);
  end

  [nsamples, nchannels] = size(samples);
  if nsamples == 0
    sampleBuffer = [];
    return
  else
    sampleBuffer = [sampleBuffer; samples];
    nsamples = rows(sampleBuffer);
    if nsamples < showFFTFigureConfig.fftSize
        return
    end
    samples = sampleBuffer(1:showFFTFigureConfig.fftSize, :);
    if nsamples > showFFTFigureConfig.fftSize
        sampleBuffer = sampleBuffer(showFFTFigureConfig.fftSize+1:end, :);
    else
        sampleBuffer = [];
    end
    nsamples = rows(samples);
  end

  if ishandle(fftFigure)
    recFFT = fft(samples .* winfun)';
    yc = recFFT(:, 1:fftSize/2 + 1) / (fftSize/2 * winmean);
    y = abs(yc);

    if (showFFTFigureConfig.numAvg > 0) ...
        && (yavgn >= showFFTFigureConfig.numAvg) ...
        && (showFFTFigureConfig.restartAvg == 0)
        return
    end
    if (showFFTFigureConfig.restartAvg == 1) ...
        || (showFFTFigureConfig.numAvg < 2) ...
        || (size(yavg) != size(y))
        showFFTFigureConfig.restartAvg = 0;
        yavg = y;
        yavgn = 1;
    else
        yavg = ((yavg .* yavgn) .+ y) ./ (yavgn + 1);
        yavgn += 1;
    end
    for i=1:nchannels
      set(fftLine(i), 'YData', 20*log10(yavg(i,:)));
    end
  end
endfunction

function logXTickZoomHandler(h)
  xt = get(h,'XTick');
  set(h,'XTickLabel', sprintf('%4.0f|',xt))
endfunction
