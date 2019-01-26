function result = isStatus (testedStatus)
  global status;
  if (length(status) == 1 && status == testedStatus)
    result = true;
  else
    result = false;
  endif
endfunction
