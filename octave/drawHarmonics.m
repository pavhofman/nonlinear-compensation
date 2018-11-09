function drawHarmonics(x, y, label, plotID, plotsCnt, use_ylim = [-150 0])
  y = 20 * log10(y);
  subplot(plotsCnt,1,plotID);
  % semilogx requires values > 0
  x(x == 0) = 10^-10;
  semilogx(x, y, 'linewidth', 1.5, 'color', 'black');
  grid('on');
  ylim(use_ylim)
  axis([900 10000]);
  xlabel('Frequency (Hz)', 'fontsize', 10);
  ylabel('Magnitude (dB)', 'fontsize', 10);
  title(label);
  % change the tick labels of the graph from scientific notation to floating point:
  xt = get(gca,'XTick');
  set(gca,'XTickLabel', sprintf('%.0f|',xt))
  addlistener(gca, 'xlim', @logXTickZoomHandler)
endfunction

function logXTickZoomHandler(h)
  xt = get(h,'XTick');
  set(h,'XTickLabel', sprintf('%4.0f|',xt))
endfunction
