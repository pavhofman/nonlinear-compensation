function newSteps = adjustStepper(reqLevels, recInfo, playInfo)
  % const - init steps to gain calibration moves
  persistent BACKLASH_STEPS = 150;
  persistent INIT_STEPS = [0, 400, -200, 600];
  % rows of moves is kept betweeen latest MIN_MOVES and MAX_MOVES - DISABLED for now
  persistent MIN_MOVES = 15;
  persistent MAX_MOVES = 20;

  global ardStruct;
  global ANALYSED_CH_ID;
  global PLAY_CH_ID;

  if ~ardStruct.backlashCleared
    % clearing backlash
    writeLog('DEBUG', "Moving %d steps to clear stepper backlash", BACKLASH_STEPS);
    printStr("Clearing stepper backlash, calibrating stepper");
    moveStepperTo(BACKLASH_STEPS);
    ardStruct.backlashCleared = true;
    % has to calibrate
    ardStruct.calibrated = false;
    % empty moves
    ardStruct.moves = [];
    % will start at 0 - required for calculations
    ardStruct.lastSteps = 0;
    newSteps = BACKLASH_STEPS;
    return;
  endif

  playAmpl = playInfo.measuredPeaks{PLAY_CH_ID}(1, 2);
  recAmpl = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 2);
  lastStepRatio = recAmpl/playAmpl;

  % determining lastBacklashCoeff
  % NOTE: if BACKLASH_STEPS > 0, i.e. the backlash is cleared in positive direction, the backlash coeffs in fact correspond to sign of steps (positive => 0, negative => 1)
  % this whole lastBacklashCoeff calculation could be avoided and step directions used instead, but I will keep it for clarity
  if isempty(ardStruct.moves)
    % for fixed first lastStep = 0
    lastBacklashCoeff = 0;
  else
    lastDir = ardStruct.lastSteps == abs(ardStruct.lastSteps);
    prevDir = ardStruct.moves(end, 1) == abs(ardStruct.moves(end, 1));
    if xor(lastDir, prevDir)
      % direction change
      % backlash coeff inverted from previous
      lastBacklashCoeff = ~ardStruct.moves(end, 3);
    else
      % no change in direction, keeping backlash coeff from previous
      lastBacklashCoeff = ardStruct.moves(end, 3);
    endif
  endif

  % all params of new move row are available now
  newMove = [ardStruct.lastSteps, lastStepRatio, lastBacklashCoeff];
  % appending to moves
  ardStruct.moves= [ardStruct.moves; newMove];


  % DISABLED - not working properly, regression returns nonsense values
  if false
    % stepper slippage can occur, corrupting the values. Therefore it is convenient to drop older rows from moves to phase out the incorrect ones eventually.
    if rows(ardStruct.moves) > MAX_MOVES
      ardStruct.moves(1:end - MIN_MOVES, :) = [];
      ardStruct.moves(1, 1) = 0;
      % new pos0 corresponding to moves(1), must be reset so that the constraint in calculateNewStep
      ardStruct.lastPos0 = NA;
      writeLog('DEBUG', 'ardStruct.moves reached max %d rows, kept only min last %d rows in ardStruct.moves, reset lastPos0 in new step calculation',
        MAX_MOVES, MIN_MOVES);
    endif
  endif


  if ~ardStruct.calibrated
    % in calibration mode, using INIT_STEPS instead of calculated steps
    newStepIdx = rows(ardStruct.moves) + 1;
    newSteps = INIT_STEPS(newStepIdx);
    if newStepIdx == length(INIT_STEPS)
      % will use last init value, next round will be calibrated
      ardStruct.calibrated = true;
    endif
  else
    % for now only one req level
    reqTransfer = reqLevels(1)/playAmpl;
    newSteps  = calculateNewStep(ardStruct.moves, reqTransfer);
  endif
  % moving new steps
  if newSteps ~= 0
    printStr("Moving stepper %d steps", newSteps);
    moveStepperTo(newSteps);
  endif
endfunction

function newSteps = calculateNewStep(moves, reqTransfer)
  persistent INIT_BACKLASH = 20;
  % corresponds to steps required to reach next VD wire
  persistent MIN_STEPS = 2;
  global ardStruct;

  steps=moves(:, 1);
  % independent values (x)
  offsets = cumsum(steps);
  backlashCoeffs = moves(:, 3);
  x = [offsets, backlashCoeffs];  

  transfers = moves(:, 2);
  % r2/r1
  transfRatios = transfers(2:end) ./ transfers(1:end-1);

  % observed values (y)  
  obs = transfRatios;

  f = @(p, x) fitEqs(x, p(1), p(2));

  if isna(ardStruct.lastPos0)
    % pos0 must not be 0, otherwise division by zero!
    minPos0 = 1;
    maxPos0 = 30000;
  else
    % using pos0 from last calculation to avoid abrupt jumps in curvefit results
    minPos0 = 0.9 * ardStruct.lastPos0;
    maxPos0 = 1.1 * ardStruct.lastPos0;
  endif
  settings = optimset('lbound', [minPos0 ; 5], 'ubound', [maxPos0; 100]);
  init = [minPos0; INIT_BACKLASH];
  
  [p, model_values, cvg, outp] = nonlin_curvefit(f, init, x, obs, settings);
  pos0 = round(p(1));
  backlash = round(p(2));
  writeLog('DEBUG', 'Identified stepper params: pos0: %d, backlash: %d', pos0, backlash);

  % calculating newSteps
  reqTransfRatio = reqTransfer / transfers(end);
  lastPos = pos0 + offsets(end) + backlashCoeffs(end) * backlash;
  newPos = round(reqTransfRatio * lastPos);
  newSteps = newPos - lastPos;
  writeLog('DEBUG', 'Extrapolated new steps:%d', newSteps);

  % adjusting  newSteps for backlash
  % positive direction 1, negative 0
  lastDir = steps(end) == abs(steps(end))
  if xor(lastDir, newSteps > 0)
    % direction changed, increasing by safe (partial) backlash
    safeBacklash = round(backlash * 0.6);
    newSteps = ifelse(newSteps > 0, newSteps + safeBacklash, newSteps - safeBacklash);
    writeLog('DEBUG', 'Stepper direction will change, adding safe backlash %d steps', safeBacklash);
  endif

  % lower limit MIN_STEPS to avoid tiny steps
  newSteps = ifelse(newSteps > 0, max(newSteps, MIN_STEPS), min(newSteps, -MIN_STEPS));
  writeLog('DEBUG', 'Determined new steps: %d', newSteps);

  % keeping for lower/upper bounds in next run
  ardStruct.lastPos0 = pos0;
endfunction

% fitting equations
function [ratios] = fitEqs(x, pos0, backlash)
  offsets = x(:, 1);
  backlashCoeffs = x(:, 2);
  
  pos = pos0 + offsets + backlashCoeffs * backlash;
  % avoiding division by zero
  pos(pos == 0) = 0.001;
  ratios = pos(2:end) ./ pos(1:end-1);
endfunction