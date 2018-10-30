# Generating distortion polynom for output device

pkg load miscellaneous

format long e
l = 5;
leftpadz = @(p) [zeros(1,max(0,l-numel(p))),p];

# transfer of base frequency = 1
distortpoly = leftpadz( db2mag(0) * chebyshevpoly(1,1) ); 

#add distortion: 2nd harmonics -120dB
distortpoly += leftpadz( db2mag(-120) * chebyshevpoly(1,2));

#add distortion: 3nd harmonics -120dB
distortpoly += leftpadz( db2mag(-120) * chebyshevpoly(1,3));

printf("Distortion Polynomial (copy to playback route 'polynom [ xx xx xx ...]'):\n");
disp(fliplr(distortpoly));

