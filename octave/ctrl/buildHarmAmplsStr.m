% converting values from distortion dialog to harmonic Ampls string
function harmAmplsStr = buildHarmAmplsStr(values, harmCnt)
  global CMD_AMPLS_PREFIX;
  harmAmplsStr = [CMD_AMPLS_PREFIX '['];
  for harmID = 1:harmCnt;
    harmAmpl = sscanf(values{harmID}, '%f');
    if isempty(harmAmpl)
      harmAmpl = NA;
    else
      % entered in dB, passed in absolute values
      harmAmpl = db2mag(harmAmpl);
    endif
    harmAmplsStr = [harmAmplsStr num2str(harmAmpl) ','];
  endfor
  harmAmplsStr = [harmAmplsStr ']'];
endfunction

%!test
%! harmCnt = 3;
%! global CMD_AMPLS_PREFIX;
%! CMD_AMPLS_PREFIX = 'AMPL';
%! values = {'-120', '', '-140'};
%! expected = 'AMPL[1e-06,NA,1e-07,]';
%! harmAmplsStr = buildHarmAmplsStr(values, harmCnt);
%! assert(harmAmplsStr, expected);
