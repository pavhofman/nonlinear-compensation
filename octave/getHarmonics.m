% calculating FFT + harmonics up to Fs
%
% computes FFT from number of samples that is maximum whole multiple of Fs
%
% hanning window is used if precise_amplitude is 0
% flattop window is used if precise_amplitude is 1
%
% returns:
%   fundPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   distortPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   errorMsg - nonempty if finding distortion frequencies has failed
%   x - freqencies
%   y - amplitudes_in_abs_value
%
function [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(samples, Fs, genDistortPeaks = true, window_name = 'hanning')  
  %consts
  persistent maxDistortPeaksCnt = getMaxDistortPeaksCnt();
  
  [x, yc, nfft] = computeFFT(samples, Fs, window_name);
  y = abs(yc);
  % peaks for all channels must have equal row cnt so that can be stored in 3D matrix
  channelCnt = columns(yc);
  fundPeaks = cell(channelCnt, 1);
  distortPeaks = cell(channelCnt, 1);
  for channelID = 1:channelCnt
    ycCh = yc(:, channelID);
    yCh = y(:, channelID);
    [fundPeaksCh, errorMsgCh] = findFundPeaksCh(x, ycCh, yCh);
    if rows(fundPeaksCh) == 0
      % error, will PASS
      writeLog('DEBUG', "Did not find any fundPeaks in channelID %d", channelID);
    elseif rows(fundPeaksCh) > 2
      writeLog('DEBUG', "Found fundPeaks for channel ID %d: %s", channelID, disp(fundPeaksCh));
      writeLog('DEBUG', "That is more than 2 supported, will send no fund peaks");
      fundPeaksCh = [];
    endif
    % Must use double! Result of time() converted to single returns incorrect time.
    fundPeaks{channelID} = double(fundPeaksCh);
    errorMsg(:, channelID) = cellstr(errorMsgCh);
    
    if (genDistortPeaks && hasAnyPeak(fundPeaksCh))
      [distortPeaksCh] = getDistortionProductsCh(fundPeaksCh, x, ycCh, yCh, Fs / nfft);
      % limit distortPeak to maxDistortCnt rows
      if rows(distortPeaksCh) > maxDistortPeaksCnt
          % take distortPeaks strongest harmonics, keep unsorted
          distortPeaksCh = resize(sortrows(distortPeaksCh,-2), maxDistortPeaksCnt,3);
      end
      distortPeaks{channelID} = double(distortPeaksCh);
    endif    
  endfor  
 
  if genDistortPeaks
    writeLog('DEBUG', 'Determined distortion peaks: %s', disp(distortPeaks));
  endif
endfunction