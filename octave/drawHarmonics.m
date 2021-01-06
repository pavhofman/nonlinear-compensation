function drawHarmonics(x, y, label, plotID, plotsCnt, use_ylim = [-150 0], use_xlim = [900 10000])
  y = 20 * log10(y);
  subplot(plotsCnt,1,plotID);
  % skip frequencies under 10Hz
  skip = 1;
  while x(skip) < 10
      skip++;
  end
  % semilogx requires values > 0
  x(x <= 0) = 10^-10;
  semilogx(x(skip:end), y(skip:end), 'linewidth', 1.5, 'color', 'black');
  grid('on');
  ylim(use_ylim)
  xlim(use_xlim);
  xlabel('Frequency (Hz)', 'fontsize', 10);
  ylabel('Magnitude (dB)', 'fontsize', 10);
  title(label);
  % change the tick labels of the graph from scientific notation to floating point:
  xt = get(gca,'XTick');
  set(gca,'XTickLabel', sprintf('%.0f|',xt))
  addlistener(gca, 'xlim', @logXTickZoomHandler)
end

function logXTickZoomHandler(h)
  xt = get(h,'XTick');
  set(h,'XTickLabel', sprintf('%4.0f|',xt))
end
