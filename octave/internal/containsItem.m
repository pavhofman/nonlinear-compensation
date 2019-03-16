% check if array arr contains item. Does not work for cell arrays!!
function result = containsItem(arr, item)
  result = any(arr == item);  
endfunction


%!test
%! arr = [1, 2];
%! assert(true, containsItem(arr, 2));
%! assert(false, containsItem(arr, 3));