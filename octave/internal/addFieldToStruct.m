% adding new field to struct
function structVar = addFieldToStruct(structVar, field)
  if ~isfield(structVar, field)
    structVar.(field) = struct();
  end
end
