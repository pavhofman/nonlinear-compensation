function result = isStatus (testedStatus)
  global info;
  status = info.status;
  if (length(status) == 1 && status == testedStatus)
    result = true;
  else
    result = false;
  endif
endfunction
