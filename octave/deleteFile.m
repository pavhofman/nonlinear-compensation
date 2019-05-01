function deleteFile(filePath)
  if exist(filePath, 'file')
    delete(filePath);
    writeLog('DEBUG', 'Deleted file %s', filePath);
  endif
endfunction