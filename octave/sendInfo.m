% sending zeroMQ message with info struct to zeromqPort
function sendInfo(info, zeromqPort)
  persistent id = 0;
  persistent sock = zmq_socket (ZMQ_PAIR);
  persistent result = zmq_connect(sock, ['tcp://localhost:' num2str(zeromqPort)]);
  
 
  info.time = time();
  info.id = id;
  ser = var2bytea(info);
  writeLog('TRACE', "Sending info: %d bytes", length(ser));
  zmq_send (sock, ser, ZMQ_DONTWAIT);  
  id += 1;
endfunction