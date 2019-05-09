function [transfer] = lowPass(f, coeffs)
  r1 = coeffs(1);
  c1 = coeffs(2);
  rin = coeffs(3);
  
  om = 2 * pi * f;
  
  x1 = 1./(j * om * c1);
  z1 = x1 .* rin./(x1 + rin);
  
  transferComplex = z1./(r1 + z1); 
  transfer = [ abs(transferComplex)', angle(transferComplex)'];
endfunction

