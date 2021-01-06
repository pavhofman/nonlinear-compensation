function result = statusContains(testedStatus)
  global statusStruct;  
  result = structContains(statusStruct, testedStatus);
end
