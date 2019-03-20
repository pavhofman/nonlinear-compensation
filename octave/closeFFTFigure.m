function closeFFTFigure()
  global showFFTCfg;
  if ~isna(showFFTCfg.fig) && isfigure(showFFTCfg.fig)
    close(showFFTCfg.fig);
  endif
  showFFTCfg.fig = NA;
  showFFTCfg.enabled = false;
endfunction
