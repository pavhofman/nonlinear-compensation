% setting adapter params to default values
function resetAdapterStruct(recoverInOut = true)
  global adapterStruct;

  % initialization
  if ~isfield(adapterStruct, 'prevOut')
    adapterStruct.prevOut = [];
  endif

  if ~isfield(adapterStruct, 'prevIn')
    adapterStruct.prevIn = [];
  endif

  % in/out recovery
  if recoverInOut &&  ~isempty(adapterStruct.prevOut)
    adapterStruct.out = adapterStruct.prevOut;
    % reset
    adapterStruct.prevOut = [];
  else
    % default
    adapterStruct.out = false; % OUT OFF
  endif

  if recoverInOut &&  ~isempty(adapterStruct.prevIn)
    adapterStruct.in = adapterStruct.prevIn;
    % reset
    adapterStruct.prevIn = [];
  else
    % default
    adapterStruct.in = false; % IN CALIB
  endif

  % other switches defaults
  adapterStruct.lpf = false; % VD
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];

  % flag for indicating that phase of setting switches is finished
  adapterStruct.switchesSet = false;
  % flag indicating change in switches
  adapterStruct.switchesChanged = false;
endfunction