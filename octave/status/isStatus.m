function result = isStatus (testedStatus)
  global statusStruct;
  result = structContainsOnly(statusStruct, testedStatus);
end
