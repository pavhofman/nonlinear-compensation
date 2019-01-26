% remove from status
function status = removeFromStatus(statusToRemove)
  global info;
  status = info.status;

  id = find(status == statusToRemove);
  status(id) = [];
  info.status = status;
endfunction
