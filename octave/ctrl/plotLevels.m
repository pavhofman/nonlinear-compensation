% Plotting x, y to plot line. Handles optimized value updates and visibility
function plotLevels(line, x, y)
  if ~isempty(y)
    shownX = get(line, 'XData');    
    if ~isequal(shownX, x)
      set(line, 'XData', x);
    end
    shownY = get(line, 'YData');
    if ~isequal(shownY, y)
      set(line, 'YData', y);
    end
    setVisible(line, true);
  else
    % hide
    setVisible(line, false);
  end
end