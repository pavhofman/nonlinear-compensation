% generating distortion polynomial. distortHarmAmpls are in absolute values, not in dB!
function distortPoly = genDistortPoly(distortHarmAmpls)
  harmCnt = length(distortHarmAmpls);
  distortPoly = zeros(1, harmCnt + 2);
  % first harm at 100%
  distortPoly = addPoly(chebyshevpoly(1, 1), distortPoly);
  
  for id = 1: harmCnt
    harmAmpl = distortHarmAmpls(id);
    if harmAmpl > 0
      poly = harmAmpl * chebyshevpoly(1, id + 1);
      distortPoly = addPoly(poly, distortPoly);
    end
  end
end

function wholePoly = addPoly(poly, wholePoly)
  % prepending poly with zeros to fit wholePoly length
  poly = [zeros(1, length(wholePoly) - length(poly)), poly];
  wholePoly += poly;
end
