% setting adapter params to default values
function resetAdapterStruct(recoverInOut = true)
  global adapterStruct;

  adapterStruct.label = '';
  adapterStruct.showContinueBtn = false;

  % initialization
  if ~isfield(adapterStruct, 'prevOut')
    % stack of values
    adapterStruct.prevOut = cell();
  endif

  if ~isfield(adapterStruct, 'prevIn')
    adapterStruct.prevIn = cell();
  endif

  % in/out recovery
  if recoverInOut &&  ~isempty(adapterStruct.prevOut)
    adapterStruct.out = adapterStruct.prevOut{end};
    % reset
    adapterStruct.prevOut(end) = [];
  else
    % default
    adapterStruct.out = false; % OUT OFF
  endif

  if recoverInOut &&  ~isempty(adapterStruct.prevIn)
    adapterStruct.in = adapterStruct.prevIn{end};
    % reset
    adapterStruct.prevIn(end) = [];
  else
    % default
    adapterStruct.in = false; % IN CALIB
  endif

  % other switches defaults
  adapterStruct.calibLPF = false; % VD
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];

  % flag for indicating that phase of setting switches is finished
  adapterStruct.switchesSet = false;
  % flag indicating change in switches
  adapterStruct.switchesChanged = false;
endfunction