function [buffer, fs] = readDataPlayrec(cnt, restart)
    global playRecConfig;
    persistent pageNumList;

    if isstruct(playRecConfig) && isfield(playRecConfig, 'recDeviceID')
        recDeviceID = playRecConfig.recDeviceID;
    else
        recDeviceID = 0;
    end
    if isstruct(playRecConfig) && isfield(playRecConfig, 'sampleRate')
        fs = playRecConfig.sampleRate;
    else
        fs = 48000;
    end
    if isstruct(playRecConfig) && isfield(playRecConfig, 'chanList')
        chanList = playRecConfig.chanList;
    else
        chanList = [1 2];
    end
    if isstruct(playRecConfig) && isfield(playRecConfig, 'pageBufCount')
        pageBufCount = playRecConfig.pageBufCount;
    else
        pageBufCount = 5;
    end

    if (cnt == -1)
        cnt = fs * 0.4;
    endif

    if((ndims(chanList)~=2) || (size(chanList, 1)~=1))
        error ('chanList must be a row vector');
    end

    %Test if current initialisation is ok
    if(playrec('isInitialised'))
        if(playrec('getSampleRate')~=fs)
            fprintf('Changing playrec sample rate from %d to %d\n', playrec('getSampleRate'), fs);
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
    if(restart || !playrec('isInitialised'))
        if (playrec('isInitialised'))
          playrec('reset');
        endif
        fprintf('Initialising playrec to use sample rate: %d, recDeviceID: %d and no play device\n', fs, recDeviceID);
        playrec('init', fs, -1, recDeviceID)
        if(~playrec('isInitialised'))
            error ('Unable to initialise playrec correctly');
        elseif(playrec('getRecMaxChannel')<max(chanList))
            error ('Selected device does not support %d output channels\n', max(chanList));
        end
        %Clear all previous pages
        playrec('delPage');
        playrec('resetSkippedSampleCount');
        pageNumList = [];
        for page=1:pageBufCount
            pageNumList = [pageNumList playrec('rec', cnt, chanList)];
        end
        tic();
    end

    printf('Sleeping for %f\n', cnt/fs - toc());
    playrec('block', pageNumList(1));
    buffer = playrec('getRec', pageNumList(1));
    playrec('delPage', pageNumList(1));
    tic();

    pageNumList = [pageNumList(2:end) playrec('rec', cnt, chanList)];

    skipped = playrec('getSkippedSampleCount');
    if(skipped ~= 0)
        playrec('resetSkippedSampleCount');
        printf('XRUN input: %d samples lost!!\n', skipped);
    end
endfunction
