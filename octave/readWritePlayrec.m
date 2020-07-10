function buffer = readWritePlayrec(playBuffer, cycleLength, periodSize, fs, restart)
    global playRecConfig;
    persistent pageNumList;
    
    % clearing playBuffer at restart
    if restart
      playBuffer = [];
    endif
    
    if isstruct(playRecConfig) && isfield(playRecConfig, 'recDeviceID')
        recDeviceID = playRecConfig.recDeviceID;
    else
        recDeviceID = 0;
    end
    if isstruct(playRecConfig) && isfield(playRecConfig, 'playDeviceID')
        playDeviceID = playRecConfig.playDeviceID;
    else
        playDeviceID = -1;
    end

    if isstruct(playRecConfig) && isfield(playRecConfig, 'recChanList')
        recChanList = playRecConfig.recChanList;
    else
        recChanList = [1 2];
    end
        if isstruct(playRecConfig) && isfield(playRecConfig, 'playChanList')
        playChanList = playRecConfig.playChanList;
    else
        playChanList = [1 2];
    end

    if isstruct(playRecConfig) && isfield(playRecConfig, 'pageBufCount')
        pageBufCount = playRecConfig.pageBufCount;
    else
        pageBufCount = 5;
    end

    cnt = floor(fs * cycleLength);

    if((ndims(recChanList)~=2) || (size(recChanList, 1)~=1))
        error ('chanList must be a row vector');
    end

    %Test if current initialisation is ok
    if(playrec('isInitialised'))
        if(playrec('getSampleRate')~=fs)
            writeLog('INFO', 'Changing playrec sample rate from %d to %d\n', playrec('getSampleRate'), fs);
            playrec('reset');
        elseif(playrec('getRecDevice')~=recDeviceID)
            writeLog('INFO', 'Changing playrec record device from %d to %d\n', playrec('getRecDevice'), recDeviceID);
            playrec('reset');
        elseif(playrec('getRecMaxChannel')<max(recChanList))
            writeLog('INFO', 'Resetting playrec to configure device to use more input channels\n');
            playrec('reset');
        end
    end

    %Initialise if not initialised
    if(restart || ~playrec('isInitialised'))
        if (playrec('isInitialised'))
          playrec('reset');
        endif
        writeLog('INFO', 'Initialising playrec to use sample rate: %d, recDeviceID: %d , playDeviceID: %d\n', fs, recDeviceID, playDeviceID);
        playrec('init', fs, playDeviceID, recDeviceID, 2, 2, periodSize)
        if(~playrec('isInitialised'))
            error ('Unable to initialise playrec correctly');
        elseif(playrec('getRecMaxChannel')<max(recChanList))
            error ('Selected device does not support %d output channels\n', max(recChanList));
        end
        %Clear all previous pages
        playrec('delPage');
        playrec('resetSkippedSampleCount');
        pageNumList = [];
        for page=1:pageBufCount
            pageNumList = [pageNumList playrec('rec', cnt, recChanList)];
        end
        tic();
    end

    sleepTime = cnt/fs - toc();
    if sleepTime > 0
      writeLog('TRACE', 'Sleeping for %f', sleepTime);
    else
      writeLog('WARN', 'XRUN - Sleeping only for %f', sleepTime);
    endif
    % blocking read on recording side
    playrec('block', pageNumList(1));
    buffer = playrec('getRec', pageNumList(1));
    playrec('delPage', pageNumList(1));
    tic();

    % FIFO - drop first element of pageNumList, read last from recDeviceID
    pageNumList = [pageNumList(2:end) playrec('playrec', playBuffer, playChanList, cnt, recChanList)];

    skipped = playrec('getSkippedSampleCount');
    if(skipped ~= 0)
        playrec('resetSkippedSampleCount');
        writeLog('WARN', 'XRUN input: %d samples lost!', skipped);
    end
endfunction
