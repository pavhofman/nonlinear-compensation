% loading calibration row for calculation purporses - the calfile will usually have only one peaks row when this method is called
function [peaksRow, distortFreqs] = loadCalRow(calFile)
  % loading calRec structure
  load(calFile);
  
  peaks = calRec.peaks;
  if isempty(peaks)
    msg = sprintf('Calfile %s does not have any peaks rows, unsupported operation, exiting.', calFile);
    writeLog('ERROR', msg);
    error(msg);
  end
  
  % calfile used in this method should have only one row, but for safety using the first one
  peaksRow = peaks(1, :);
  distortFreqs = calRec.distortFreqs;
end