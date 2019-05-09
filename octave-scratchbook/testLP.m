pkg load optim;
more off;
f = [500, 3000, 10000];
r1 = 10000; % 10k
c1 = 2.2e-8; % 10nF

rin = 7100; % 7.1k


coeffs = [r1; c1; rin];
preciseTransf = lowPass(f, coeffs);

% fuzzy values
randChange = 0.01* (-0.5 + rand(length(preciseTransf), 2));

fuzzyTransf = preciseTransf + randChange;

func = @ (p, x) lowPass(x, p);


initCoeffs = coeffs .* (rand(length(coeffs), 1) + 0.5);
settings = optimset ("lbound", 0.5* coeffs, "ubound", 2*coeffs, "MaxIter", 100, "TolFun", 0.00001);

[estCoeffs, estTransf, cvg, outp] = nonlin_curvefit (func, initCoeffs, f, fuzzyTransf, settings)

estCoeffs
estTransf - preciseTransf
estCoeffs - coeffs


