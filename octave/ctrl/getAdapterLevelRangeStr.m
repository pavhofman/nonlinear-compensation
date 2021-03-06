function str = getAdapterLevelRangeStr(adapterStruct)
  % only first level
  level = adapterStruct.reqVDLevel;
  maxAmplDiff = adapterStruct.maxAmplDiff;
  str = sprintf("<%6.3fdB, %6.3fdB>", 20*log10(level - maxAmplDiff), 20*log10(level + maxAmplDiff));
end


%!test
%! as = struct();
%! as.reqLevel = 0.8;
%! as.maxAmplDiff = 0.1;
%! result = getAdapterLevelRangeStr(as);
%! assert(result, '<-3.098dB, -0.915dB>');

%!test
%! as = struct();
%! as.reqLevel = 0.1;
%! as.maxAmplDiff = 0.05;
%! result = getAdapterLevelRangeStr(as);
%! assert(result, '<-26.021dB, -16.478dB>');
