% introduce distortion to buffer
if ~isempty(distortPoly)
  buffer = polyval(distortPoly, buffer);
  % clipping to <-1, 1>
  buffer(buffer > 1) = 1;
  buffer(buffer < -1) = -1;
endif
