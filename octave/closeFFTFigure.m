function closeFFTFigure()
  global showFFTCfg;
  if ~isna(showFFTCfg.fig) && isfigure(showFFTCfg.fig)
    close(showFFTCfg.fig);
  end
  showFFTCfg.fig = NA;
  showFFTCfg.enabled = false;
end
