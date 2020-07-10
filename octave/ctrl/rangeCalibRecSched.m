% scheduler-enabled function for range-calibration of REC side
% Range calibration calibrates at higher, lower, and exact level of the original signal to provide lines in calFile for interpolation
% Not using generator
% result: NA = not finished yet, false = error/failed, true = finished OK
% If PLAY-side not compensating, running joint-sides calibration, otherwise REC-side calibration
function result = rangeCalibRecSched(label = 1)
  persistent NAME = 'Range-Calibrating REC Side';

  % step above and below exact calibration level to also calibrate for interpolation
  persistent CAL_LEVEL_STEP = db2mag(-58);

  % format [adjustment1, maxAmplDiff1; adjustment2, maxAmplDiff2;...]
  % For production operation the sequence should be in one direction (up, exact, down) do speed-up level setup (clearing backlash only once).
  % But that means the last VD position will leave it at level not equal to input level, complicating testing
  % For testing let's use the suboptimal sequence with exact level as last.
  persistent MULTI_STEPS = [...
    % up
    % 2 * CAL_LEVEL_STEP,   db2mag(-75);...
    CAL_LEVEL_STEP,   db2mag(-75);...
    % down
    -CAL_LEVEL_STEP, db2mag(-75);...
    % -2 * CAL_LEVEL_STEP, db2mag(-75);...
    % very exact value
    0,                db2mag(-85);...
  ];

  result = calibRecSched(label, MULTI_STEPS, mfilename(), 'Range-Calibrating REC Side');
endfunction