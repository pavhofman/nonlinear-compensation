% introduce distortion to buffer
if ~isempty(distortPoly)
  buffer = polyval(distortPoly, buffer);
endif
