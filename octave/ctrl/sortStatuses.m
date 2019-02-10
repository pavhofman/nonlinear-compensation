% sorting statuses in statusStruct based on status order template
function sortedStatuses = sortStatuses(statusStruct, orderTemplate)
  statuses = cell();
  orderInTemplate = [];
  
  for [statusVal, status] = statusStruct
    idx = find(ismember(orderTemplate, status));
    if isempty(idx)
      idx = 100;
    endif
    statuses{end + 1} = status;
    orderInTemplate = [orderInTemplate, idx];
  endfor
  
  % sort by idx
  [dummy, sortedOrder ] = sort(orderInTemplate);
  sortedStatuses = statuses(sortedOrder);
endfunction

%!test 
%! orderTemplate = {'a', 'b', 'c'};
%! statusStruct = struct();
%! statusStruct.b.q = 5;
%! statusStruct.d.w = 5;
%! statusStruct.a.o = 5;
%! sortedStatuses = sortStatuses(statusStruct, orderTemplate);
%! assert(sortedStatuses, {'a', 'b', 'd'});

%! statusStruct = struct();
%! sortedStatuses = sortStatuses(statusStruct, orderTemplate);
%! assert(sortedStatuses, {});

