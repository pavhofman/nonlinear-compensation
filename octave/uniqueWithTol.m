% unique with tolerance
function [y, i, j] = uniqueWithTol(x, tolerance, varargin)
  if size(x, 1) == 1
    x = x(:);
  endif

  if nargin < 2 || isempty(tolerance) || tolerance == 0
      [y, i, j] = unique(x,varargin{:});
      return;
  endif

  [y, i, j] = unique(x, varargin{:});
  if size(x, 2) > 1
      [~, ord] = sort(sum(x.^2, 1), 2, 'descend');
      [y, io] = sortrows(y,ord);
      [~, jo] = sort(io);
      i = i(io);
      j = jo(j);
  endif

  difference = sum(abs(diff(y, 1, 1)), 2);
  isTol = [true; difference > tolerance];
  y = y(isTol, :);
  bin = cumsum(isTol);
  j = bin(j);
  i = i(isTol);
endfunction