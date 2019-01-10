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
  persistent maxFundPeaksCnt = getMaxFundPeaksCnt();
  persistent maxDistortPeaksCnt = getMaxDistortPeaksCnt();
  
  [x, yc, nfft] = computeFFT(samples, Fs, window_name);
  y = abs(yc);
  % peaks for all channels must have equal row cnt so that can be stored in 3D matrix
  channelCnt = columns(yc);
  fundPeaks = zeros(maxFundPeaksCnt, 3, channelCnt);
  distortPeaks = zeros(maxDistortPeaksCnt, 3, channelCnt);
  for channelID = 1:channelCnt
    ycCh = yc(:, channelID);
    yCh = y(:, channelID);
    [fundPeaksCh, errorMsgCh] = findFundPeaksCh(x, ycCh, yCh);
    if rows(fundPeaksCh) == 0
      % error, will PASS
      printf("Did not find any fundPeaks, will send zeros\n");
      fundPeaksCh = zeros(maxFundPeaksCnt, 3);
    elseif rows(fundPeaksCh) > maxFundPeaksCnt
      printf("Found fundPeaks for channel ID %d:\n", channelID);
      disp(fundPeaksCh);      
      printf("That is more than %d supported, will send zeros", maxFundPeaksCnt);
      fundPeaksCh = zeros(maxFundPeaksCnt, 3);
    endif
    
    fundPeaks(1:rows(fundPeaksCh), :, channelID) = fundPeaksCh;
    errorMsg(:, channelID) = cellstr(errorMsgCh);
    
    if (genDistortPeaks && hasAnyPeak(fundPeaksCh))
      [distortPeaksCh] = getDistortionProductsCh(fundPeaksCh, x, ycCh, yCh, Fs / nfft);
      % limit distortPeak to maxDistortCnt rows
      if rows(distortPeaksCh) > rows(distortPeaks)
          % take distortPeaks strongest harmonics, keep unsorted
          distortPeaksCh = resize(sortrows(distortPeaksCh,-2), rows(distortPeaks),3);
      end
      distortPeaks(1:rows(distortPeaksCh), :, channelID) = distortPeaksCh;
    endif    
  endfor  
 
  printf('Determined fundamental peaks:\n');
  %disp(fundPeaks);
  if genDistortPeaks
    printf('Determined distortion peaks:\n');
    %disp(distortPeaks);
  endif
endfunction