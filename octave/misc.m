# custom function fitting


plotFreq(recorded, "Recorded", 1, fs, plotsCnt);

#plotFreq(reference, "Reference", 2, fs, plotsCnt);


polyCoeff = polyfit(recorded, reference, 5);
disp(fliplr(polyCoeff));


recovered = polyval(polyCoeff, recorded);

plotFreq(recovered, "Recovered", 3, fs, plotsCnt);

f = @ (p, x) p(1) * nthroot(x, 3) + p(2) + p(3)*x + p(4)*x.^2 + p(5) * x.^3 + p(6) * x.^4 + p(7) * x.^5;
init = [0; 0; 1; 0;0; 0; 0];
[p, model_values, cvg, outp] = nonlin_curvefit (f, init, recovered, reference);

recovered2 = f(p, recovered);

plotFreq(recovered2, "Recovered2", 4, fs, plotsCnt);
disp(p');
return;

#residual analysis
residual = recovered - reference;
showFFT(residual, "Residual", 3, fs, plotsCnt);
disp(fliplr(polyCoeff));

residualGain = fliplr(polyfit(recovered - reference, reference, 5))(2);

scaledReference = reference / residualGain;

recovered2 = recovered - polyval(polyfit(residual, scaledReference, 5), residual);

showFFT(recovered2, "Recovered 2", 4, fs, plotsCnt);

recovered3 = polyval(polyfit(recovered2, reference, 5), recovered2);
showFFT(recovered3, "Recovered 3", 5, fs, plotsCnt);




completePoly = polyfit(recorded, recovered3, 15);
showFFT(polyval(completePoly, recorded), "Recovered 4", 5, fs, plotsCnt);

disp(fliplr(polyCoeff)*0.5);
disp(fliplr(polyCoeff)*-0.5);
return;

# identifying distortion below HW limits
l = 5;
leftpadz = @(p) [zeros(1,max(0,l-numel(p))),p];
distortpoly = leftpadz( db2mag(0) * chebyshevpoly(1,1) ); 
distortpoly += leftpadz( db2mag(-120) * chebyshevpoly(1,2));

refdistort = polyval(distortpoly, reference);
showFFT(refdistort, "Reference Distortion", 3, fs, plotsCnt);

recordedWithdistort = polyval(distortpoly, recorded);
showFFT(recordedWithdistort, "Recorded with Distortion", 4, fs, plotsCnt);

recovereddistort = polyval(polyCoeff, recordedWithdistort);
showFFT(recovereddistort, "Recovered Distortion", 5, fs, plotsCnt);


