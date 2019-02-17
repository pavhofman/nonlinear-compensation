function result = statusContains(testedStatus)
  global statusStruct;
  result = isfield(statusStruct, testedStatus);
endfunction
