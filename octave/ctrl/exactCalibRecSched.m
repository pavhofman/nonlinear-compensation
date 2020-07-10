% scheduler-enabled function for range-calibration of REC side
% Single-level calibration
% result: NA = not finished yet, false = error/failed, true = finished OK
% If PLAY-side not compensating, running joint-sides calibration, otherwise REC-side calibration
function result = exactCalibRecSched(label = 1)
  % format [adjustment1, maxAmplDiff1; adjustment2, maxAmplDiff2;...]
  persistent SINGLE_STEP = [...
    % single very exact value
    0,                db2mag(-85);...
  ];

  result = calibRecSched(label, SINGLE_STEP, mfilename(), 'Exact-Level Calibrating REC Side');
endfunction