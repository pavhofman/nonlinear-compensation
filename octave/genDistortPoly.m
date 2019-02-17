% generating distortion polynomial. distortHarmLevels are already in absolute values, not in dB!
function distortPoly = genDistortPoly(distortHarmLevels)
  harmCnt = length(distortHarmLevels);
  distortPoly = zeros(1, harmCnt + 2);
  % first harm at 100%
  distortPoly = addPoly(chebyshevpoly(1, 1), distortPoly);
  
  for id = 1: harmCnt
    harmLevel = distortHarmLevels(id);
    if harmLevel > 0
      poly = harmLevel * chebyshevpoly(1, id + 1);
      distortPoly = addPoly(poly, distortPoly);
    endif
  endfor
endfunction

function wholePoly = addPoly(poly, wholePoly)
  % prepending poly with zeros to fit wholePoly length
  poly = [zeros(1, length(wholePoly) - length(poly)), poly];
  wholePoly += poly;
endfunction
