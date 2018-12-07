function result = statusIs (status, testedStatus)
  if (length(status) == 1 && status == testedStatus)
    result = true;
  else
    result = false;
  endif
endfunction
