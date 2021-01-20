% setting adapter params to default values
function resetAdapterStruct(recoverInOut = true)
  global adapterStruct;

  adapterStruct.label = '';

  % initialization
  if ~isfield(adapterStruct, 'prevOut')
    % stack of values
    adapterStruct.prevOut = cell();
  end

  if ~isfield(adapterStruct, 'prevIn')
    adapterStruct.prevIn = cell();
  end

  % in/out recovery
  if recoverInOut &&  ~isempty(adapterStruct.prevOut)
    adapterStruct.out = adapterStruct.prevOut{end};
    % reset
    adapterStruct.prevOut(end) = [];
  else
    % default
    adapterStruct.out = adapterStruct.defaultOut;
  end

  if recoverInOut &&  ~isempty(adapterStruct.prevIn)
    adapterStruct.in = adapterStruct.prevIn{end};
    % reset
    adapterStruct.prevIn(end) = [];
  else
    % default
    adapterStruct.in = false; % IN CALIB
  end

  % other switches defaults
  adapterStruct.vdLpf = false; % VD
  % single value
  adapterStruct.reqVDLevel = [];
  adapterStruct.maxAmplDiff = [];

  % flag for indicating that phase of setting switches is finished
  adapterStruct.switchesSet = false;
  % flag indicating change in switches
  adapterStruct.switchesChanged = false;

  adapterStruct.gndPlus = false;
  % default - SE always grounded -
  adapterStruct.gndMinus = adapterStruct.isSE;

  % ID of stepper to operate in checkStepper
  adapterStruct.stepperToMove = [];
end