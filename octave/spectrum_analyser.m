#!/usr/bin/octave -qf

recDeviceID = 0;
chanList = [1 2];

%function [ ] = spectrum_analyser( recDeviceID, chanList)
%SPECTRUM_ANALYSER Uses Playrec to implement a basic spectrum analyser.
%
%   spectrum_analyser( recDeviceID, chanList) creates two figures, one
%   displaying the spectrum and another the waveform recorded from the
%   specified playrec device, recDeviceID, on the channels chanList.
%
%   The script runs until either interrupted or both figures are closed.

Fs = 48000;

% Increase these values to ensure output stability (ie resilience to
% glitches) at the expense of a longer latency
pageSize = Fs;    %size of each page processed
pageBufCount = 6;   %number of pages of buffering

fftSize = pageSize;

runMaxSpeed = false; %When true, the processor is used much more heavily 
                     %(ie always at maximum), but the chance of glitches is 
                     %reduced without increasing latency

if((ndims(chanList)~=2) || (size(chanList, 1)~=1))
    error ('chanList must be a row vector');
end

%Test if current initialisation is ok
if(playrec('isInitialised'))
    if(playrec('getSampleRate')~=Fs)
        fprintf('Changing playrec sample rate from %d to %d\n', playrec('getSampleRate'), Fs);
        playrec('reset');
    elseif(playrec('getRecDevice')~=recDeviceID)
        fprintf('Changing playrec record device from %d to %d\n', playrec('getRecDevice'), recDeviceID);
        playrec('reset');
    elseif(playrec('getRecMaxChannel')<max(chanList))
        fprintf('Resetting playrec to configure device to use more input channels\n');
        playrec('reset');
    end
end

%Initialise if not initialised
if(~playrec('isInitialised'))
    fprintf('Initialising playrec to use sample rate: %d, recDeviceID: %d and no play device\n', Fs, recDeviceID);
    playrec('init', Fs, -1, recDeviceID)
end
    
if(~playrec('isInitialised'))
    error ('Unable to initialise playrec correctly');
elseif(playrec('getRecMaxChannel')<max(chanList))
    error ('Selected device does not support %d output channels\n', max(chanList));
end

%Clear all previous pages
playrec('delPage');

function logXTickZoomHandler(h)
  xt = get(h,'XTick');
  set(h,'XTickLabel', sprintf('%4.0f|',xt))
endfunction

colors = {'red';'blue'};

fftFigure = figure;
fftAxes = axes('parent', fftFigure, 'xlimmode', 'manual', 'ylimmode', 'manual', 'xscale', 'log', 'yscale', 'linear', 'xlim', [10 Fs/2], 'ylim', [-150, 0]);
fftXAxisData = (0 : (fftSize / 2)) * Fs / fftSize;
for i=1:length(chanList)
    fftLine(i) = line(
            'XData', fftXAxisData,
            'YData', ones(1, fftSize/2 + 1),
            'Color', char(colors(i)));
end
xlabel('Frequency (Hz)', 'fontsize', 10);
ylabel('Magnitude (dB)', 'fontsize', 10);
% change the tick labels of the graph from scientific notation to floating point:
xt = get(gca,'XTick');
set(gca,'XTickLabel', sprintf('%.0f|',xt))
addlistener(gca, 'xlim', @logXTickZoomHandler)

timeFigure = figure;
timeAxes = axes('parent', timeFigure, 'xlimmode', 'manual', 'ylimmode', 'manual', 'xscale', 'linear', 'yscale', 'linear', 'xlim', [1 pageSize], 'ylim', [-1, 1]);
for i=1:length(chanList)
    timeLine(i) = line(
        'XData', 1:pageSize,
        'YData', ones(1, pageSize),
        'Color', char(colors(i))
    );
end

infoFigure = figure;
infoText(1) = text(5, 0, '','fontsize', 12, 'fontname','courier','verticalalignment','top','horizontalalignment','left');
if length(chanList) == 1
axis([-100 0 -100 0], 'off');
else
infoText(2) = text(-5, 0, '','fontsize', 12, 'fontname','courier','verticalalignment','top','horizontalalignment','right');
axis([-100 100 -100 0], 'off');
end

drawnow;

recSampleBuffer = zeros(fftSize, length(chanList));

% Create vector to act as FIFO for page numbers
pageNumList = repmat(-1, [1 pageBufCount]);

firstTimeThrough = true;

while(ishandle(fftFigure) || ishandle(timeFigure) || ishandle(infoFigure))
    pageNumList = [pageNumList playrec('rec', pageSize, chanList)];

    if(firstTimeThrough)
        %This is the first time through so reset the skipped sample count
        playrec('resetSkippedSampleCount');
        firstTimeThrough = false;
    else
        if(playrec('getSkippedSampleCount'))
            fprintf('%d samples skipped!!\n', playrec('getSkippedSampleCount'));
            %return
            %Let the code recover and then reset the count
            firstTimeThrough = true;
        end
    end
    
    % runMaxSpeed==true means a very tight while loop is entered until the
    % page has completed whereas when runMaxSpeed==false the 'block'
    % command in playrec is used.  This repeatedly suspends the thread
    % until the page has completed, meaning the time between page
    % completing and the 'block' command returning can be much longer than
    % that with the tight while loop
    if(runMaxSpeed)
        while(playrec('isFinished', pageNumList(1)) == 0)
        end
    else
        playrec('block', pageNumList(1));
    end
   
    lastRecording = playrec('getRec', pageNumList(1));
    if(~isempty(lastRecording))
        %very basic processing - windowing would produce a better output
        recSampleBuffer = [recSampleBuffer(length(lastRecording) + 1:end, :); lastRecording];
        if ishandle(fftFigure) || ishandle(infoFigure)
            winlen = length(recSampleBuffer);
            winfun = hanning(winlen);
            recFFT = fft(recSampleBuffer .* winfun);
            yc = recFFT(1:fftSize/2 + 1, :) / (winlen/2 * mean(winfun));
            y = abs(yc);
        end
        if ishandle(fftFigure)
            for i=1:length(chanList)
                set(fftLine(i), 'YData', 20*log10(y(:,i)));
            end
        end
        if ishandle(infoFigure)
            for i=1:length(chanList)
                [fundPeaks, distortPeaks, errorMsg] = findHarmonicsFromFFT(yc(:,i), y(:,i), fftXAxisData, Fs / fftSize);
                peaks = [fundPeaks; distortPeaks];
                peaks2 = convertPeaksToPrintable(peaks);
                set(infoText(i), 'String', sprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', peaks2'));
            end
        end
        if ishandle(timeFigure)
            for i=1:length(chanList)
                set(timeLine(i), 'YData', lastRecording(:,i));
            end
        end
    end

    drawnow;
    
    playrec('delPage', pageNumList(1));
    %pop page number from FIFO
    pageNumList = pageNumList(2:end);
end
    
%delete all pages now loop has finished
playrec('delPage');
%endfunction

