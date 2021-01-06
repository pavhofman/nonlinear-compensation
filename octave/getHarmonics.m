% calculating FFT + harmonics up to Fs
%
% computes FFT from fftLength samples
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
function [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(fftLength, samples, fs, genDistortPeaks = true, window_name = 'rect')
  global MAX_DISTORT_ID;

  [x, yc, nfft] = computeFFT(samples, fftLength, window_name);
  y = abs(yc);
  % peaks for all channels must have equal row cnt so that can be stored in 3D matrix
  channelCnt = columns(yc);
  fundPeaks = cell(channelCnt, 1);
  distortPeaks = cell(channelCnt, 1);
  for channelID = 1:channelCnt
    ycCh = yc(:, channelID);
    yCh = y(:, channelID);
    [fundPeaksCh, errorMsgCh] = findFundPeaksCh(x, ycCh, yCh);
    errorMsg(:, channelID) = cellstr(errorMsgCh);
    if rows(fundPeaksCh) == 0
      % error, will PASS
      writeLog('DEBUG', "Did not find any fundPeaks in channelID %d", channelID);
    end

    % generating distortion peaks
    if (genDistortPeaks && hasAnyPeak(fundPeaksCh))
      [distortPeaksCh] = getDistortionProductsCh(fundPeaksCh, x, ycCh, yCh, fftLength / nfft);
      % limit distortPeak to maxDistortCnt rows
      if rows(distortPeaksCh) > MAX_DISTORT_ID
          % take distortPeaks strongest harmonics, keep unsorted
          distortPeaksCh = resize(sortrows(distortPeaksCh,-2), MAX_DISTORT_ID,3);
      end
      if ~isempty(distortPeaksCh)
        % converting bin ID to Hz
        distortPeaksCh(:, 1) = distortPeaksCh(:, 1) * fs / fftLength;
        % storing
        distortPeaks{channelID} = double(distortPeaksCh);
      end
    end

    if ~isempty(fundPeaksCh)
      % converting bin ID to Hz
      fundPeaksCh(:, 1) = fundPeaksCh(:, 1) * fs / fftLength;
      % storing. Must use double! Result of time() converted to single returns incorrect time.
      fundPeaks{channelID} = double(fundPeaksCh);
    end

    if rows(fundPeaksCh) > 2
      writeLog('DEBUG', "Found fundPeaks for channel ID %d: %s", channelID, disp(fundPeaksCh));
      writeLog('DEBUG', "That is more than 2 supported, will send no fund peaks");
      fundPeaksCh = [];
    end
  end
 
  if genDistortPeaks
    writeLog('TRACE', 'Determined distortion peaks: %s', disp(distortPeaks));
  end
end