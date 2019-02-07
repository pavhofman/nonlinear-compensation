function result = isStatus (testedStatus)
  global statusStruct;
  result = numfields(statusStruct) == 1 && statusContains(testedStatus);
endfunction
