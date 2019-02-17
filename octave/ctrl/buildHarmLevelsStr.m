% converting values from distortion dialog to harmonic levels string
function harmLevelsStr = buildHarmLevelsStr(values, harmCnt)
  global CMD_HARM_LEVELS_PREFIX;
  harmLevelsStr = [CMD_HARM_LEVELS_PREFIX '['];
  for harmID = 1:harmCnt;
    harmLevel = sscanf(values{harmID}, '%f');
    if isempty(harmLevel)
      harmLevel = NA;
    endif
    harmLevelsStr = [harmLevelsStr num2str(harmLevel) ','];
  endfor
  harmLevelsStr = [harmLevelsStr ']'];
endfunction

%!test
%! harmCnt = 3;
%! values = {'-120', '', '-140'};
%! expected = 'HL[-120,NA,-140,]';
%! harmLevelsStr = buildHarmLevelsStr(values, harmCnt);
%! assert(harmLevelsStr, expected);
