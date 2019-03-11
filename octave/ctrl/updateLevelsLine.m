% updating plot line with levels at x
function updateLevelsLine(levels, line, x)  
  % plotting levels
  x = repmat(x, rows(levels), 1);
  if length(levels) == 2
    % shiting second level to the right by CH_DISTANCE_X 
    global CH_DISTANCE_X;
    x(2) += CH_DISTANCE_X;
  endif
  plotLevels(line, x, levels);
endfunction
  
  