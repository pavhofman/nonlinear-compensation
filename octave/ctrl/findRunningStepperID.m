function stepperID = findRunningStepperID()
  global steppers;

  for idx = 1:length(steppers)
    stepper = steppers{idx};
    if stepper.running
      stepperID = stepper.ID;
      return;
    endif
  endfor

  % did not find any
  stepperID = [];
endfunction