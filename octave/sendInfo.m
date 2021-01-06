% sending zeroMQ message with info struct to zeromqPort
function sendInfo(infoStruct, zeromqPort)
  persistent id = 0;
  persistent sock = zmq_socket (ZMQ_PAIR);
  persistent result = zmq_connect(sock, ['tcp://localhost:' num2str(zeromqPort)]);
  
 
  infoStruct.id = id;
  ser = var2bytea(infoStruct);
  writeLog('TRACE', "Sending infoStruct: %d bytes, ID %d", length(ser), infoStruct.id);
  zmq_send (sock, ser, ZMQ_DONTWAIT);  
  id += 1;
end