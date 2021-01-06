% receiving zeromq message from sock
function info = rcvInfo(sock)
  % const
  % waiting for ms
  persistent WAIT_MS = 50;
  info = [];

  try
    hasData = zmq_poll(sock, WAIT_MS);
    if (hasData)
      % info struct is long
      % 0 = blocking mode
      data = zmq_recv (sock, 50000, 0);
      info = bytea2var(data);
    end
  catch err
    writeLog('ERROR', err.message);
  end

end
