% add an item to row arr if not there yet. Does not work for cell arrays!!
function arr = addItemToRow(arr, item)
  if ~any(arr == item)
    % does not contain yet
    arr = [arr, item];
  endif
endfunction


%!test
%! arr = [1, 2];
%! assert([1, 2, 3], addItemToRow(arr, 3));
%! assert([1, 2], addItemToRow(arr, 2));
