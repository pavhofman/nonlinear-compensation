% remove field from struct if exists
function structVar = removeFromStruct(structVar, field)
  if isfield(structVar, field)
    structVar = rmfield(structVar, field);
  end
end
