function result = structContainsOnly (structVar, field)
  result = numfields(structVar) == 1 && structContains(structVar, field);
end