function deleteFile(filePath)
  if exist(filePath, 'file')
    delete(filePath);
  endif
endfunction