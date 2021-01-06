% updating plot line with levels at x
function updateLevelsLine(levels, line, x)  
  % plotting levels
  % levels must be column
  if isrow(levels)
    levels = transpose(levels);
  end
  x = repmat(x, rows(levels), 1);
  if length(levels) == 2
    % shifting second level to the right by CH_DISTANCE_X 
    global CH_DISTANCE_X;
    x(2) += CH_DISTANCE_X;
  end
  plotLevels(line, x, levels);
end
  
  